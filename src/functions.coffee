request = require 'request'
db = require './database'

exports.name = 'bitbucket'
exports.desc = 'forward bitbucket notification'


exports.setup = (telegram, store, server) ->
  parser = require './parser'
  pkg = require '../package.json'
  config = require '../config.json'
  db.connect()
  db.create()

  [
      cmd: 'hello'
      num: 0
      desc: 'Just hello'
      act: (msg) =>
        telegram.sendMessage msg.chat.id, 'Hello, world'
    ,
      cmd: 'echo'
      args: '<something>'
      num: 1
      desc: 'echo <something>'
      act: (msg, sth) =>
        telegram.sendMessage msg.chat.id, sth
    ,
      cmd: 'id'
      num: 0
      debug: yes
      desc: 'Get ID of this chat.'
      act: (msg) ->
        telegram.sendMessage msg.chat.id, msg.chat.id
    ,
      cmd: 'repo:push'
      num: -1
      desc:'Do not call this method. It is used by bitbucket webhook'
      act: (msg) ->
        # push object parser and handle logic
        chat_id = config
        for chat_id in config.push_ids
          telegram.sendMessage chat_id, parser.parseNotification(msg), parse_mode = "Markdown"
    ,
      cmd: 'secret'
      num: 0
      desc: 'If you could decode the message, you will know the secret command'
      act: (msg) ->
        secretMsg = new Buffer 'Here are the secret commands:\n/anime\n/meizi\nUse `/help command` to see the details'
          .toString 'base64'
        telegram.sendMessage msg.chat.id, secretMsg, parse_mode = "Markdown"
    ,
      cmd: 'hitokoto'
      num: 3
      opt: 3
      desc: 'Get one sentence'
      act: (msg, cat, mix, ucat) =>
        api = "http://api.hitokoto.us/rand"
        qs = {}
        qs.cat = cat if cat?
        qs.mix = mix if mix?
        qs.ucat = ucat if mix? and ucat?
        console.log(qs)
        request {url: api, qs: qs, json:true}, (err, req, res) ->
          console.log(res)
          telegram.sendMessage msg.chat.id, res.hitokoto if res.hitokoto?
    ,
      cmd: 'hint'
      num: 2
      opt: 1
      desc: 'Add a message as a hint that could be queried later\n
             cmd are: a(dd) l(ist) s(earch) g(et)\n
             usage:\n
             /hint a "a hint" -  add reply message(start with /) as a hint with title "a hint"\n
             /hint l [page] - list hints, 10 hints per page\n
             /hint s keyword - search hints contains keyword\n
             /hint g id  - get a detail information of a hit'
      act: (msg, cmd, option) =>
        switch cmd
          # for add, option is the title
          when "a", "add" then handleHint telegram, msg, "add", option
          # for search, option is the keyword
          when "s", "search" then handleHint telegram, msg, "search", option
          # for list, option is the page
          when "l", "list" then handleHint telegram, msg, "list", option
          # for get, option is the id
          when "g", "get" then handleHint telegram, msg, "get", option

  ]

exports.hack = ->
  [
    name: 'bitbucket'
    hack: (req) ->
      ###
      # hack here, if req header contains User-Agent Bitbucket-Webhooks/2.0 forward
      # Notification. 
      # req.params will play as the message object in telegram Update
      # object(Update.message)
      # A base message object:

      "message": {
        "message_id": 1,
        "from": {
          "id": 1,
          "first_name": "xxx",
          "last_name": "xxx",
          "username": "xxx"
        },
        "chat": {
          "id": 1,
          "first_name": "xxx",
          "last_name": "xxx",
          "username": "xxx",
          "type": "private"
        },
        "date": 1450953645,
        "text": "/echo hello"
      }
      ###
      # req.params.text = '/{X-Event-Key(repo:push)}'
      # If hack done, reutrn true else return false
      ua = req.header 'User-Agent'
      if ua? and ua .toLowerCase null
          .indexOf('bitbucket') >= 0
        req.params.message_id = 1
        req.params.text = '/' + req.header 'X-Event-Key'
        req.params.chat = {}
        req.params.chat.id = 1
        req.params.from = {}
        req.params.from.id = 1
        return true
      return false
  ]

handleHint = (telegram, msg, cmd, option) =>
    try

      trimMessage = (message) ->
          m = message.split('\n')
          m = if m.length > 1 then m[0] + "..." else m[0]
          message = if m.length <= 40 then m else m.substr(0, 37) + '...'
      switch cmd
        when "add"
          if !msg.reply_to_message?
            text = "Please supply a reply message starting with a line containing a /"
            return telegram.sendMessage msg.chat.id, text

          # trim the first line if it is startsWith /
          # Use Shift+Enter, there will be a \n
          # Use Ctrl+Enter, there will be a space join the first two lines
          t = msg.reply_to_message.text
          if t.startsWith("/")
            # trim char / and line-break
            t = t.substr(2)
          else
            t = msg.reply_to_message.text

          db.add option, t, msg.from.username, (err) =>
            if (err?)
              text = err
            else
              text = "Hint \'#{option}\' is added to hint list."
            telegram.sendMessage msg.chat.id, text
        when "search"
          db.search option, (rows) =>
            res = for {id, title, hints, author} in rows
              "#{id}: #{title} - #{trimMessage hints}... - by #{author}"
            console.log(res)
            text = res.join "\n"
            text = if text.length != 0 then text else "oops! nothing found."
            telegram.sendMessage msg.chat.id,  text
        when "list"
          db.list option, (rows, totalnum) =>
            res = for {id, title, hints, author} in rows
              "#{id}: #{title} - #{trimMessage hints} - by #{author}"
            console.log(res)
            text = res.join "\n"
            text = if text.length != 0 then text else "oops! nothing found."
            if totalnum > 0
              pages = [1..Math.ceil(totalnum / 10)]
              pages = pages.join(' | ')
              if option?
                pages = pages.replace(option, "*#{option}*")
              else
                pages = pages.replace("1", "*1*")
              text += "\n------------\nPages: #{pages}\n"
            telegram.sendMessage msg.chat.id, text, parse_mode = "Markdown"
        when "get"
          db.get option, (rows) =>
            res = for {id, title, hints, author} in rows
              "#{title}\n\n#{hints}\n\nBy #{author}"
            console.log(res)
            text = res.join "\n"
            text = if text.length != 0 then text else "oops! nothing found."
            telegram.sendMessage msg.chat.id, text
    catch err
      console.log err

