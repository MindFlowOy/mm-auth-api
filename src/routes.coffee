"use strict"

###
* ---
*   Routes module
*   @name routes
*   @api public
###


# Hapi
Hapi = require 'hapi'
# Hapi types for validation
Types = require('hapi').types

Passport = undefined

module.exports =
    setPassport: (PassportInst)->
        Passport = PassportInst

    routes: [

        # Login form handler - not needed if session routes below used
        method: "GET"
        path: "/login"
        config:
              auth: false
              handler: (request) ->
                    if request.session._isAuthenticated()
                          request.reply.redirect "/home"
                    else
                          form = "<p><a href=\"/auth/google\">Login with Google</a></p><form action=\"/login\" method=\"post\"> <div> <label>Username:</label> <input type=\"text\" name=\"username\"/> </div> <div> <label>Password:</label> <input type=\"password\" name=\"password\"/> </div> <div> <input type=\"submit\" value=\"Log In\"/> </div> </form>"
                          request.reply form

    ,   # Login form handler - not needed if session routes below used
        method: "POST"
        path: "/login"
        config:
            validate:
                payload:
                      username: Hapi.types.String()
                      password: Hapi.types.String()

              auth: false
              handler: (request) ->
                    Passport.authenticate("local") request, ->
                    request.reply
                            status: 200

    ,   # Create new session
        method: "POST"
        path: "/aa/session"
        config:
            validate:
                query: {}
                payload:
                  username: Hapi.types.String().required().description("username")
                  password: Hapi.types.String().required().description("password")

            auth: false
            handler: (request) ->
                Passport.authenticate("local") request, ->
                        request.reply
                            status: 200

            description: "Create"
            notes: "Logs user in and creates session."
            tags: [ "api" ]

    ,   # Get current session
        method: "GET"
        path: "/aa/session"
        config:
              auth: false
              handler: (request) ->
                    request.reply  request.session
                    request.session

              description: "Show"
              notes: "Shows current request session"
              tags: [ "api" ]

    ,   # End session (used instead of del just because it can be tested better from swagger)
        method: "PUT"
        path: "/aa/session"
        config:
              auth: false
              handler: (request) ->
                    console.log "CLEAR SESSION"
                    request.session._logout()
                    request.session.reset()
                    request.reply
                            status: 200

              description: "Reset"
              notes: "Reset (delete) current request session"
              tags: [ "api" ]

    ,   # Remove current session
        method: "DELETE"
        path: "/aa/session"
        config:
              auth: false
              handler: (request) ->
                    request.session._logout()
                    request.reply
                            status: 200

              description: "Remove"
              notes: "Removes current request session (=log out)"
              tags: [ "api" ]

    ,   # Google authentication
        method: "GET"
        path: "/auth/google"
        config:
            auth: false
            handler: (request) ->
                Passport.authenticate("google") request

    ,   # Google authentication return address
        method: "GET"
        path: "/auth/google/return"
        config:
              auth: false
              handler: (request) ->
                    Passport.authenticate("google",
                          failureRedirect: options.urls.failureRedirect
                          successRedirect: options.urls.successRedirect
                          failureFlash: true
                    ) request, (err) ->
                          request.session.error = err  if err and err.isBoom
                          request.reply.redirect "/"

        ]
