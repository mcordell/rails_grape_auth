// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require_tree .
//
//


global.jQuery = require('jquery');
(function () {
  'use strict';

      var $     = require('jquery'),
      colorbox  = require('jquery-colorbox'),
      auth      = require('j-toker'),
      apiUrl    = 'http://grape.dev/rails_api/',
      postsPath = 'posts',
      configureAuth = function () {
        auth.configure({
          apiUrl: apiUrl
        });
      },
      signIn = function (username, password, successCallback) {
        auth.emailSignIn({
          email: username,
          password: password
        }).then(function (user) {
          if (successCallback) {
            successCallback(user);
          }
        })
        .fail(function (resp) {
          alert('Authentication failure: ' + resp.errors.join(' '));
        });
      },
      checkLoggedIn = function (isLoggedInCallback) {
        auth.validateToken()
            .then(isLoggedInCallback)
            .fail(signInProcess(isLoggedInCallback));
      },
      getPosts = function (callback) {
        var url = apiUrl + postsPath;
        $.getJSON(url).success(callback);
      },
      bindGetPosts = function (callback) {
        $('button#get-posts').click( function (event) {
          event.preventDefault();
          checkLoggedIn(getPosts(callback));
        });
      },
      bindLoginSubmit = function (successCallback) {
        $('button#sign-in-submit').click( function (event) {
          var email = $('input[name="user-email"]').val(),
              password = $('input[name="user-password"]').val();
          event.preventDefault();
          $.colorbox.close();
          signIn(email, password, successCallback);
        });
      },
      signInProcess = function (callback) {
        displaySignedInModal(callback);
      },
      displaySignedInModal = function (completeCallback) {
        $.colorbox({html:'<div class="box" width: "400"><h1>Welcome</h1><label for="user-emai">Email</label><input name="user-email"/><label for="password"> Password</label><input type="password" name="user-password" /> <button id="sign-in-submit">Sign in</button></div>',
        onComplete: function() { bindLoginSubmit(completeCallback)}
        });
      },
      bindLogin = function (callback) {
        $('button#login').click( function (event) {
          event.preventDefault();
          displaySignedInModal(callback);
        });
      };

  $(document).ready(function () {
    configureAuth();
    bindLogin(function (user) { alert('Welcome ' + user.data.email + '!'); });
    bindGetPosts();
  });
}());
