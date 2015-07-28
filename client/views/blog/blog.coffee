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


Template.disqus.rendered = ->

  if Blog.settings.comments.disqusShortname
    # Don't load the Disqus embed.js into the DOM more than once
    if window.DISQUS
      # If we've already loaded, call reset instead. This will find the correct
      # thread for the current page URL. See:
      # http://help.disqus.com/customer/portal/articles/472107-using-disqus-on-ajax-sites
      post = @data

      window.DISQUS.reset
        reload: true
        config: ->
          @page.identifier = post.id
          @page.title = post.title
          @page.url = window.location.href
    else
      disqus_shortname = Blog.settings.comments.disqusShortname
      disqus_identifier = @data.id
      disqus_title = @data.title
      disqus_url = window.location.href
      disqus_developer = 1

      dsq = document.createElement("script")
      dsq.type = "text/javascript"
      dsq.async = true
      dsq.src = "//" + disqus_shortname + ".disqus.com/embed.js"
      (document.getElementsByTagName("head")[0] or document.getElementsByTagName("body")[0]).appendChild dsq

Template.disqus.helpers
  useDisqus: ->
    Blog.settings.comments.disqusShortname
