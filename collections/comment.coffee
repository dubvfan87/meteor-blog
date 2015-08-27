class @Comment extends Minimongoid

  @_collection: new Meteor.Collection 'blog_comments'

  @belongs_to: [
    {
      name: 'post'
      identifier: 'postId'
    }
    {
      name: 'author'
      identifier: 'userId'
    }
  ]

  validate: ->
    if not @body
      @error 'body', "body is required"

    if not @userId
      @error 'userId', "userId is required"

    if not @postId
      @error 'postId', "postId is required"

Comment._collection.allow
  insert: (userId, doc) ->
    !!userId
  update: (userId, doc, fields, modifier) ->
    doc.userId == userId
  remove: (userId, doc) ->
    doc.userId == userId || Meteor.call 'isBlogAuthorized', ite
    