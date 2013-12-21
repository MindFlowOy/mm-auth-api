'use strict'

###
* ---
*   Auth Index
*   @name index
*   @api public
###


Hapi = require("hapi")
LocalStrategy = require("passport-local").Strategy
GoogleStrategy = require("passport-google").Strategy

# Routes module
routes  = require './routes'

## Just dummy list of users for first tests
USERS = MindFlow: "test"

exports.register = (plugin, options, next) ->

    # Get passprot object from main module
    Passport = options.passport

    # Handler of passport local srategy http://passportjs.org/guide/username-password/
    Passport.use new LocalStrategy (username, password, done) ->
        # TODO: Find or create user here...
        # In real prog, use password hashing like bcrypt
        if USERS.hasOwnProperty(username) and USERS[username] is password
            return done(null,
                username: username
            )
        done null, false,
            message: "invalid credentials"


    # Handler of passport Google srategy http://passportjs.org/guide/google/
    Passport.use new GoogleStrategy options.google, (identifier, profile, done) ->
        console.log "GOOGLE accessToken", identifier
        console.log "GOOGLE profile", profile
        # TODO: Find or create user here...
        done null, profile


    Passport.serializeUser (user, done) ->
        done null, user

    Passport.deserializeUser (obj, done) ->
        done null, obj

    # Add server routes
    routes.setPassport(Passport)
    plugin.route route for route in routes.routes

    next()
