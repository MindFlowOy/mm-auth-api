var Hapi = require('hapi');
var LocalStrategy = require('passport-local').Strategy;
var GoogleStrategy = require('passport-google').Strategy;


var USERS = {
    "vli": "test"
};



exports.register = function (plugin, options, next) {


    var Passport = options.passport


    Passport.use(new LocalStrategy(function (username, password, done) {
        // Find or create user here...
        // In production, use password hashing like bcrypt
        if (USERS.hasOwnProperty(username) && USERS[username] == password) {
            return done(null, true, { username: username });
        }
        return done(null, false, { 'message': 'invalid credentials' });
    }));


    Passport.use(new GoogleStrategy(options.google, function (accessToken, refreshToken, profile, done) {
        console.log ("GOOGLE accessToken", accessToken);
        console.log ("GOOGLE refreshToken", refreshToken);
        console.log ("GOOGLE profile", profile);
        // Find or create user here...
        return done(null, profile);
    }));


    Passport.serializeUser(function (user, done) {
        done(null, user);
    });

    Passport.deserializeUser(function (obj, done) {
        done(null, obj);
    });



    if (process.env.DEBUG) {
        plugin.events.on('internalError', function (request, err) {
            // Send to console
            console.log("INTERNAL ERROR");
            console.log(err);
        });
    }


    // addRoutes
    /*
    plugin.route({
        method: 'GET',
        path: '/',
        config: {
            auth: 'passport', // replaces ensureAuthenticated
            handler: function (request) {

                // If logged in already, redirect to /home
                // else to /login
                request.reply.redirect('/home');
            }
        }
    });
    */

    // render json out to http stream
    function renderJSON( request, error, result ){
        if(error){
            request.reply(new hapi.error(500, error));
        }else{
            request.reply(result).type('application/json; charset=utf-8');
        }
    }

    // this is not real route, but more like example
    plugin.route({
        method: 'GET',
        path: '/login',
        config: {
            auth: false,
            handler: function (request) {
                if (request.session._isAuthenticated()) {
                    request.reply.redirect('/home');
                } else {
                    var form = '<p><a href="/auth/google">Login with Google</a></p><form action="/login" method="post"> <div> <label>Username:</label> <input type="text" name="username"/> </div> <div> <label>Password:</label> <input type="password" name="password"/> </div> <div> <input type="submit" value="Log In"/> </div> </form>';
                    request.reply(form);
                }
            }
        }
    });


    /*
     {
        method: 'POST',
        path: '/products',
        config: {
            handler: addProduct,
            payload: 'parse',
            validate: { payload: { name: Types.String().required().min(3) } } } }
    */
    plugin.route({
        method: 'POST',
        path: '/aa/session',
        config: {
            validate: {
                query: {},
                payload: {
                    username: Hapi.types.String().required().description('username'),
                    password: Hapi.types.String().required().description('password')
                }
            },
            auth: false,
            handler: function (request) {
                Passport.authenticate('local')(request,
                    function(){
                        renderJSON( request, null,  {});
                    }
                );
            },
            description: 'Create',
            notes: 'Logs user in and creates session. Redirects to the "" on success case and to the "/login" on failure case ',
            tags: ['api'],
        }
    });


    plugin.route({
        method: 'PUT',
        path: '/aa/session',
        config: {
            auth: false,
            handler: function (request) {
                console.log('CLEAR SESSION');
                request.session._logout();
                request.session.reset();
                renderJSON( request, null,  {});
                //request.reply.redirect('/aa/session');
            },
            description: 'Reset',
            notes: 'Reset (delete) current request session',
            tags: ['api'],
        }
    });


    plugin.route({
        method: 'GET',
        path: '/aa/session',
        config: {
            auth: false,
            handler: function (request) {
                renderJSON( request, null,  request.session)
                //return request.reply("<pre>" + JSON.stringify(request.session, null, 2) + "</pre><br/><br/><a href='/login'>Login</a>");
            },
            description: 'Show',
            notes: 'Shows current request session',
            tags: ['api'],
        }
    });


    plugin.route({
        method: 'DELETE',
        path: '/aa/session',
        config: {
            auth: false,
            handler: function (request) {
                request.session._logout();
                renderJSON( request, null,  {});
                //return request.reply.redirect('/');
            },
            description: 'Remove',
            notes: 'Removes current request session (=log out)',
            tags: ['api'],
        }
    });

    plugin.route({
        method: 'GET',
        path: '/auth/google',
        config: {
            auth: false,
            handler: function (request) {

                Passport.authenticate('google')(request);
            }
        }
    });



    plugin.route({
        method: 'GET',
        path: '/auth/google/return',
        config: {
            auth: false,
            handler: function (request) {

                Passport.authenticate('google', {
                    failureRedirect: options.urls.failureRedirect,
                    successRedirect: options.urls.successRedirect,
                    failureFlash: true
                })(request, function (err) {

                    if (err && err.isBoom) {
                        request.session.error = err;
                    }
                    return request.reply.redirect('/');
                });
            }
        }
    });

    next();
}
