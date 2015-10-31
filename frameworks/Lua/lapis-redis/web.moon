lapis = require "lapis"
get_redis = require "lapis.redis"
import Model from require "lapis.db.model"
import config from require "lapis.config"
import insert from table
import sort from table
import min, random from math


---

function redisRandomWorld(callback) {
  var id = h.randomTfbNumber();
  var redisId = redisWorldId(id);
  client.get(redisId, function (err, worldValue) {
    var world = {
      id: id,
      randomNumber: worldValue
    }
    callback(err, world);
  });
}

function redisSetWorld(world, callback) {
  var redisId = redisWorldId(world.id);
  client.set(redisId, world.randomNumber, function (err, result) {
    callback(err, world);
  });
}

function redisGetAllFortunes(callback) {
  client.lrange('fortunes', 0, -1, function (err, fortuneMessages) {
    if (err) { return process.exit(1); }

    var fortunes = fortuneMessages.map(function (e, i) {
      return { id: i + 1, message: e }
    });

    callback(err, fortunes)
  });
}


module.exports = {

  SingleQuery: function(req, res) {
    redisRandomWorld(function (err, world) {
      if (err) { return process.exit(1); }

      h.addTfbHeaders(res, 'json');
      res.end(JSON.stringify(world));
    })
  },

  MultipleQueries: function(queries, req, res) {
    var queryFunctions = h.fillArray(redisRandomWorld, queries);

    async.parallel(queryFunctions, function (err, worlds) {
      if (err) { return process.exit(1); }

      h.addTfbHeaders(res, 'json');
      res.end(JSON.stringify(worlds));
    })
  },

  Fortunes: function(req, res) {
    redisGetAllFortunes(function (err, fortunes) {
      if (err) { return process.exit(1); }

      h.addTfbHeaders(res, 'html');
      fortunes.push(h.ADDITIONAL_FORTUNE);
      fortunes.sort(function (a, b) {
        return a.message.localeCompare(b.message);
      });
      res.end(h.fortunesTemplate({
        fortunes: fortunes
      }));
    });
  },

  Updates: function(queries, req, res) {
    var getFunctions = h.fillArray(redisRandomWorld, queries);

    async.parallel(getFunctions, function (err, worlds) {
      if (err) { return process.exit(1); }

      var updateFunctions = [];

      worlds.forEach(function (w) {
        w.id = h.randomTfbNumber();
        updateFunctions.push(function (callback) {
          if (err) { return process.exit(1); }

          return redisSetWorld(w, callback);
        });
      });

      async.parallel(updateFunctions, function (err, updated) {
        if (err) { return process.exit(1); }

        h.addTfbHeaders(res, 'json');
        res.end(JSON.stringify(updated));
      });
    });

  }

---

class Fortune extends Model

class World extends Model

class Benchmark extends lapis.Application
  "/": =>
    json: {message: "Hello, World!"}

  "/db": =>
      w = redis\get random(1,10000)
      return json: {id:w.id,randomNumber:math.random(10000)}

  "/queries": =>
    num_queries = tonumber(@params.queries) or 1
    if num_queries < 2
      w = redis\get random(1,10000)
      return json: {{id:w.id,randomNumber:math.random(10000)}}

    worlds = {}
    num_queries = min(500, num_queries)
    for i = 1, num_queries
      w = redis\get random(1, 10000)
      redis\set worlds, id:w.id,randomNumber:w.randomnumber}
    json: worlds

  "/fortunes": =>
    @fortunes = Fortune\select ""
    redis\set @fortunes, {id:0, message:"Additional fortune added at request time."}
    sort @fortunes, (a, b) -> a.message < b.message

    layout:false, @html ->
      raw '<!DOCTYPE HTML>'
      html ->
        head ->
          title "Fortunes"
        body ->
          element "table", ->
            tr ->
              th ->
                text "id"
              th ->
                text "message"
            for fortune in *@fortunes
              tr ->
                td ->
                  text fortune.id
                td ->
                  text fortune.message

  "/update": =>
    num_queries = tonumber(@params.queries) or 1
    if num_queries == 0
      num_queries = 1
    worlds = {}
    num_queries = min(500, num_queries)
    for i = 1, num_queries
      wid = random(1, 10000)
      world = redis\get wid
      world.randomnumber = random(1, 10000)
      world\update "randomnumber"
      redis\set worlds, {id:world.id,randomNumber:world.randomnumber}
    if num_queries < 2
      return json: {worlds[1]}
    json: worlds

  "/plaintext": =>
    content_type:"text/plain", layout: false, "Hello, World!"
