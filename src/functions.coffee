request = require 'request'

exports.name = 'bitbucket'
exports.desc = 'forward bitbucket notification'

exports.setup = (telegram, store, server) ->
  parser = require './parser'
  pkg = require '../package.json'
  config = require '../config.json'

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
      num: 0
      desc: 'Add a message as a hint that could be queried later'
      act: (msg) ->
        console.log(msg.reply_to_message.text) if msg.reply_to_message?.text?

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
