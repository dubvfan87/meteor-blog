## METHODS

# Return current post if we are editing one, or empty object if this is a new
# post that has not been saved yet.
getPost = (id) ->
  (Post.first( { _id : id } ) ) or {}

# reads image dimensions and takes a callback
# callback passes params (width, height, fileName)
readImageDimensions = (file, cb) ->
  reader = new FileReader
  image = new Image
  reader.readAsDataURL file

  reader.onload = (_file) ->
    image.src = _file.target.result

    image.onload = ->
      w = @width
      h = @height
      n = file.name
      cb(w,h,n) # callback with width, height as params
      return

    image.onerror = ->
      alert 'Invalid file type: ' + file.type


# Find tags using typeahead
substringMatcher = (strs) ->
  (q, cb) ->
    matches = []
    pattern = new RegExp q, 'i'

    _.each strs, (ele) ->
      if pattern.test ele
        matches.push
          val: ele

    cb matches

# Save
save = (tpl, cb) ->
  $form = tpl.$('form')

  body = tpl.$('.froala-reactive-meteorized').editable('getHTML')

  #if not body
  #  return cb(null, new Error 'Blog body is required')

  slug = $('[name=slug]', $form).val()
  description = $('[name=description]', $form).val()

  attrs =
    title: $('[name=title]', $form).val()
    tags: $('[name=tags]', $form).val()
    slug: slug
    description: description
    body: body
    updatedAt: new Date()

  if getPost( Session.get('postId') ).id
    post = getPost( Session.get('postId') ).update attrs
    if post.errors
      return cb(null, new Error _(post.errors[0]).values()[0])
    cb null

  else
    Meteor.call 'doesBlogExist', slug, (err, exists) ->
      if not exists
        attrs.userId = Meteor.userId()
        post = Post.create attrs
        if post.errors
          return cb(null, new Error _(post.errors[0]).values()[0])
        cb post.id
      else
        return cb(null, new Error 'Blog with this slug already exists')


## TEMPLATE CODE


Template.blogAdminEdit.rendered = ->

  # We can't use reactive template vars for contenteditable :-(
  # (https://github.com/meteor/meteor/issues/1964). So we put the single-post
  # subscription in an autorun. If we're loading an existing post, once its
  # ready, we populate the contents via jQquery. The catch is, we only want to
  # run it once because when we set the contents, we lose our cursor position
  # (re: autosave).
  ranOnce = false
  @autorun =>
    sub = Meteor.subscribe 'singlePostById', Session.get('postId')
    # Load post body initially, if any
    if sub.ready() and not ranOnce
      ranOnce = true
      post = getPost( Session.get('postId') )
      if post?.body
        @$('.froala-reactive-meteorized').editable('setHTML', post.body, false)

      # Tags
      $tags = @$('[data-role=tagsinput]')
      $tags.tagsinput confirmKeys: [13, 44, 9]
      $tags.tagsinput('input').typeahead(
        highlight: true,
        hint: false
      ,
        name: 'tags'
        displayKey: 'val'
        source: substringMatcher Tag.first().tags
      ).bind 'typeahead:selected', (obj, datum) ->
        $tags.tagsinput 'add', datum.val
        $tags.tagsinput('input').typeahead 'val', ''

  imageUploadToS3 = $('.froala-reactive-meteorized').editable('option', 'imageUploadToS3');
  console.log imageUploadToS3

  # Auto save
  @$('.froala-reactive-meteorized').on 'editable.contentChanged', (e, editor) =>
    save @, (id, err) ->
      if err
        sAlert.error
          sAlertIcon: 'times-circle'
          sAlertTitle: 'Error'
          message: err.message
        return

      if id
        # If new blog post, subscribe to the new post and update URL
        Session.set 'postId', id
        path = Router.path 'blogAdminEdit', id: id
        Iron.Location.go path, { replaceState: true, skipReactive: true }

      sAlert.success
        sAlertIcon: 'check-circle'
        sAlertTitle: 'Success'
        message: 'Autosaved',
        stack: false,
        timeout: 1000



Template.blogAdminEdit.helpers
  post: ->
    getPost( Session.get('postId') )

  fileUploadReady: ->
    post = getPost( Session.get('postId') )
    if post?._id
      return ''
    return 'disabled'

  froalaButtons: ->
    return [
        'bold',
        'italic', 
        'underline',
        'strikeThrough'
        'formatBlock',
        'insertOrderedList',
        'insertUnorderedList',
        'table',
        'insertImage',
        'insertVideo',
        'createLink',
        'fullscreen',
        'html'
      ]

  froalaS3Config: ->
    tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    policy = {
      "expiration": tomorrow.toISOString()
      "conditions": [
        {"acl": Meteor.settings.public.blog.s3Config.acl},
        {"bucket": Meteor.settings.public.blog.s3Config.bucket},
        {"success_action_status": "201"},
        {"x-requested-with": "xhr"},
        ["starts-with", "$Content-Type", ''],
        ["starts-with", "$key", "s3Imports/" ]
      ]        
    }

    signature = CryptoJS.HmacSHA1(
      CryptoJS.enc.Base64.stringify(CryptoJS.enc.Utf8.parse(JSON.stringify(policy))),
      Meteor.settings.public.blog.s3Config.secretAccessKey
    ).toString(CryptoJS.enc.Base64)

    return {
      bucket: Meteor.settings.public.blog.s3Config.bucket
      region: 's3',
      keyStart: 's3Imports/'
      callback: (url, key) ->
        console.log url
        console.log key
      params:
        acl: Meteor.settings.public.blog.s3Config.acl
        AWSAccessKeyId: Meteor.settings.public.blog.s3Config.accessKey
        policy: CryptoJS.enc.Base64.stringify(
                  CryptoJS.enc.Utf8.parse(JSON.stringify(policy))
                )
        signature: signature
    }

Template.blogAdminEdit.events

  'blur [name=title]': (e, tpl) ->
    slug = tpl.$('[name=slug]')
    title = $(e.currentTarget).val()

    if not slug.val()
      slug.val Post.slugify(title)

  'change [name=featured-image]': (e, tpl) ->
    the_file = $(e.currentTarget)[0].files[0]
    post = getPost Session.get('postId')
    # get dimensions
    readImageDimensions the_file, (width, height, name) ->
      post.update
        featuredImageWidth: width
        featuredImageHeight: height
        featuredImageName: name
    # S3
    if Meteor.settings?.public?.blog?.useS3
      S3Files.insert the_file, (err, fileObj) ->
        Tracker.autorun (c) ->
          theFile = S3Files.find({_id: fileObj._id}).fetch()[0]
          if theFile.isUploaded() and theFile.url?()
            if post.id?
              post.update
                featuredImage: theFile.url()
              c.stop()
    # Local Filestore
    else
      # cfs id
      id = FilesLocal.insert
        _id: Random.id()
        contentType: 'image/jpeg'
      # format data
      formdata = new FormData()
      formdata.append('file', the_file)
      $.ajax
        type: "post"
        url: "/fs/#{id}"
        xhr: ->
          xhr = new XMLHttpRequest()
          xhr.upload.onprogress = (data) ->
            # upload progress is avilable here if needed
          xhr
        cache: false
        contentType: false
        processData: false
        data: formdata
        complete: (jqxhr) ->
          if post.id?
            post.update
              featuredImage: "/fs/#{id}"
            saAlert.success
              sAlertIcon: 'check-circle'
              sAlertTitle: 'Success'
              message: 'Featured image saved!'

  'change [name=background-title]': (e, tpl) ->
    $checkbox = $(e.currentTarget)
    getPost(Session.get("postId")).update
      titleBackground: $checkbox.is(':checked')

  'submit form': (e, tpl) ->
    e.preventDefault()
    save tpl, (id, err) ->
      if err
        return sAlert.error
          sAlertIcon: 'times-circle'
          sAlertTitle: 'Error'
          message: err.message
      Router.go 'blogAdmin'
