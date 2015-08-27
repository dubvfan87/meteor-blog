Template.blogIndex.rendered = ->
  # Page Title
  document.title = "Blog"
  if Blog.settings.title
    document.title += " | #{Blog.settings.title}"


Template.blogShowBody.rendered = ->

  Meteor.call 'isBlogAuthorized', @id, (err, authorized) =>
      if authorized
        Session.set 'canEditPost', authorized

  ####

  # Page Title
  document.title = "#{@data.title}"
  if Blog.settings.title
    document.title += " | #{Blog.settings.title}"

  # Hide draft posts from crawlers
  if not @data.published
    $('<meta>', { name: 'robots', content: 'noindex,nofollow' }).appendTo 'head'

  # featured image resize
  if Session.get "postHasFeaturedImage"
    post = Post.first({slug: Router.current().params.slug})
    $(window).resize ->
      Session.set "fullWidthFeaturedImage", $(window).width() < post.featuredImageWidth
    $(window).trigger "resize" # so it runs once


Template.blogShowBody.events
  'click a#edit-post': (event, template) ->
    event.preventDefault()
    postId = Post.first({slug: Router.current().params.slug})._id
    Router.go 'blogAdminEdit', {id: postId}

Template.blogShowBody.helpers
  isAdmin: () ->
    Session.get "canEditPost"
  shareData: () ->
    post = Post.first slug: Session.get('slug')

    {
      title: post.title,
      excerpt: post.excerpt,
      description: post.description,
      author: post.authorName(),
      thumbnail: post.thumbnail()
    }

Template.blogComments.events
  'submit form': (event, template) ->
    event.preventDefault()
    postId = Post.first(slug: Router.current().params.slug)._id
    body = template.$('.froala-reactive-meteorized').editable('getHTML')

    attrs =
      postId: postId
      body: body
      userId: Meteor.userId()
      createdAt: new Date

    comment = Comment.create attrs

    body = template.$('.froala-reactive-meteorized').editable('setHTML', '')
    #saAlert.success
    #  sAlertIcon: 'check-circle'
    #  sAlertTitle: 'Success'
    #  message: 'Your comment has been saved'



Template.blogComments.helpers
  commentsSorted: ->
    post = Post.first slug: Router.current().params.slug
    return post.commentsSorted(post._id)

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

Template.blogCommentItem.helpers
  username: ->
    return @author.username

Template.blogCommentItem.events
  'click .removeMessage': (event, template) ->
    messageId = $(event.currentTarget).data('message-id')
    comment = Comment.first({_id: messageId})
    comment.destroy()
