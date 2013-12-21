Lab = require 'lab'
Hapi = require 'hapi'

# Test shortcuts
expect = Lab.expect
before = Lab.before
after = Lab.after
describe = Lab.experiment
it = Lab.test


describe '/users/me', ->

    it 'GET returns an error when requested without auth', (done) ->
        done()
