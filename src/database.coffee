sqlite3 = require 'sqlite3'
exports.db =  db = undefined

# connect before invoke other methods
exports.connect = connect = ->
  # tbb-db stands for telegram-bot-bitbucket database
  db = new sqlite3.Database('tbb-db') if !db?

exports.create = create = ->
  db.serialize ->
    db.get "select name from sqlite_master where type='table' and name='tbb'", (err, row) ->
      if !row?
        db.run "create table tbb (
                  title text,
                  hints text,
                  author text)"

exports.close = close = ->
  db.close()


exports.add = add = (title, hints, author, callback) ->
  db.serialize ->
    db.run "insert into tbb (title, hints, author)
              values (?, ?, ?)", [title, hints, author], (err) ->
                callback err

# Search title and hints with keyword and handle result with callback
# callback accept a rows object return by db.all callback function:w
exports.search = search = (keyword, callback) ->
  db.serialize ->
    db.all "select rowid as id, * from tbb
              where title like ?
              or hints like ?", ["%#{keyword}%", "%#{keyword}%"], (err, rows) ->
                if (err?)
                  return console.log err
                callback rows

exports.list = list = (page, callback) ->
  if page? and !(!isNaN(parseInt(page)) and isFinite(page))
    return callback [], 0
  offset = if page? then (parseInt(page) - 1) * 10 else 0
  db.serialize ->
    total = 0
    db.all "select count(rowid) as totalnum from tbb", (err, rows) =>
      total = rows[0].totalnum

    db.all "select rowid as id, * from tbb
               limit 10 offset #{offset}", (err, rows) ->
                 callback rows, total

exports.get = get = (id, callback) ->
  if !id? or !(!isNaN(parseFloat(id)) and isFinite(id) and (id % 1 == 0))
    return callback []
  id = parseFloat id
  console.log id
  db.serialize ->
    db.all "select rowid as id, * from tbb
              where rowid = ?", [id], (err, rows) ->
                if (err?)
                  return console.log err
                callback rows

