Package.describe({
  summary: "A package that provides a simple blog at /blog and admin interface at /admin/blog",
  version: "0.7.1",
  name: "mattimo:blog",
  git: "https://github.com/dubvfan87/meteor-blog.git"
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.0');

  var both = ['client', 'server'];

  // PACKAGES FOR CLIENT

  api.use([
    'session',
    'templating',
    'ui',
    'less',
    'underscore',
    'aslagle:reactive-table@0.5.5',
    'juliancwirko:s-alert',
    'juliancwirko:s-alert-stackslide',
    'froala:editor',
    'froala:editor-reactive',
    'socialize:commentable'
  ], 'client');

  // FILES FOR CLIENT

  api.addFiles([

    // STYLESHEETS
    'client/stylesheets/lib/bootstrap-tagsinput.css',

    // JAVASCRIPT LIBS
    'client/boot.coffee',
    'client/compatibility/bootstrap-tagsinput.js',
    'client/compatibility/typeahead.jquery.js',
    'client/compatibility/beautify-html.js',

    // PACKAGE FILES
    'client/views/404.html',
    'client/views/custom.html',
    'client/views/custom.coffee',
    'client/views/admin/admin.less',
    'client/views/admin/admin.html',
    'client/views/admin/admin.coffee',
    'client/views/admin/edit.html',
    'client/views/admin/edit.coffee',
    'client/views/blog/blog.less',
    'client/views/blog/blog.html',
    'client/views/blog/show.html',
    'client/views/blog/blog.coffee',
    'client/views/widget/latest.html',
    'client/views/widget/latest.coffee'
  ], 'client');

  // STATIC ASSETS FOR CLIENT

  api.addFiles([
    'public/default-user.png',
    'client/stylesheets/images/remove.png',
    'client/stylesheets/images/link.png',
    'client/stylesheets/images/unlink.png',
    'client/stylesheets/images/resize-bigger.png',
    'client/stylesheets/images/resize-smaller.png'
  ], 'client', { isAsset: true });

  // FILES FOR SERVER

  api.addFiles([
    'collections/config.coffee',
    'server/boot.coffee',
    'server/publications.coffee'
  ], 'server');

  // PACKAGES FOR SERVER

  //Npm.depends({ rss: '0.0.4' });

  // PACKAGES FOR SERVER AND CLIENT

  api.use([
    'coffeescript',
    'deps',
    'iron:router@1.0.0',
    'iron:location@1.0.0',
    'accounts-base',
    'kaptron:minimongoid@0.9.1',
    'momentjs:moment',
    'vsivsi:file-collection@1.1.0',
    'alanning:roles@1.2.13',
    'meteorhacks:fast-render@2.0.2',
    'meteorhacks:subs-manager@1.2.0',
    'cfs:standard-packages@0.5.3',
    'cfs:filesystem@0.1.1',
    'cfs:s3@0.1.1',
    'jparker:crypto-core',
    'jparker:crypto-sha256',
    'jparker:crypto-hmac',
    'jparker:crypto-base64'
  ], both);

  // FILES FOR SERVER AND CLIENT

  api.addFiles([
    'collections/author.coffee',
    'collections/post.coffee',
    'collections/comment.coffee',
    'collections/tag.coffee',
    'collections/files.coffee',
    'router.coffee'
  ], both);
});

Package.onTest(function (api) {
  api.use("dubvfan87:blog", ['client', 'server']);
  api.use('tinytest', ['client', 'server']);
  api.use('test-helpers', ['client', 'server']);
  api.use('coffeescript', ['client', 'server']);
});
