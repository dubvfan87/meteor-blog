################################################################################
# Client-side Config
#

Blog =
  settings:
    title: ''
    blogIndexTemplate: null
    blogShowTemplate: null
    blogNotFoundTemplate: null
    blogAdminTemplate: null
    blogAdminEditTemplate: null
    pageSize: 20
    publicDrafts: true
    excerptFunction: null
    syntaxHighlighting: false
    syntaxHighlightingTheme: 'github'
    cdnFontAwesome: true
    comments:
      allowAnonymous: false
      defaultImg: '/packages/blog/public/default-user.png'
      userImg: 'avatar'

  config: (appConfig) ->
    # No deep extend in underscore :-(
    if appConfig.comments
      @settings.comments = _.extend(@settings.comments, appConfig.comments)
      delete appConfig.comments
    @settings = _.extend(@settings, appConfig)


@Blog = Blog


################################################################################
# Bootstrap Code
#


Meteor.startup ->
  if Blog.settings.cdnFontAwesome
    # Load Font Awesome
    $('<link>',
      href: '//netdna.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.css'
      rel: 'stylesheet'
    ).appendTo 'head'

  # Listen for any 'Load More' clicks
  $('body').on 'click', '.blog-load-more', (e) ->
    e.preventDefault()
    if Session.get 'postLimit'
      Session.set 'postLimit', Session.get('postLimit') + Blog.settings.pageSize

################################################################################
# Register Global Helpers
#

UI.registerHelper "blogFormatDate", (date) ->
  moment(new Date(date)).format "MMM Do, YYYY"

UI.registerHelper "blogFormatTags", (tags) ->
  return if !tags?

  for tag in tags
    path = Router.path 'blogTagged', tag: tag
    if str?
      str += ", <a href=\"#{path}\">#{tag}</a>"
    else
      str = "<a href=\"#{path}\">#{tag}</a>"
  return new Spacebars.SafeString str

UI.registerHelper "joinTags", (list) ->
  if list
    list.join ', '

UI.registerHelper "blogPager", ->
  if Post.count() is Session.get 'postLimit'
    return new Spacebars.SafeString '<a class="blog-load-more btn" href="#">Load More</a>'

UI.registerHelper "session", (key) ->
  return Session.get key
