##############################################################################
# Server-side config
#

Blog =
  settings:
    adminRole: null
    adminGroup: null
    authorRole: null
    authorGroup: null

  config: (appConfig) ->
    @settings = _.extend(@settings, appConfig)

@Blog = Blog

################################################################################
# Bootstrap Code
#

Meteor.startup ->

  ##############################################################################
  # Migrations
  #

  Post._collection._ensureIndex 'slug': 1
  #Comment._collection._ensureIndex 'slug': 1

  # Create 'excerpt' field if none
  if Post.where({ excerpt: { $exists: 0 }}).length
    arr = Post.where({ excerpt: { $exists: 0 }})
    i = 0
    while i < arr.length
      obj = arr[i++]
      obj.update({ excerpt: Post.excerpt(obj.body) })

  # Set version flag
  if not Config.first()
    Config.create versions: ['0.5.0']
  else
    Config.first().push versions: '0.5.0'

  # Ensure tags collection is non-empty
  if Tag.count() == 0
    Tag.create
      tags: ['meteor']
