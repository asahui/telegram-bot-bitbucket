exports.name = 'bitbucket'
exports.desc = 'forward bitbucket notification'

exports.setup = (telegram, store, server) ->
  parser = require './parser'
  pkg = require '../package.json'

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
        chat_id = 147652367
        #push_notification = 'some one push code on bitbucket'
        telegram.sendMessage chat_id, parser.parseNotification(msg), parse_mode = "Markdown"
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
      if (req.header 'User-Agent'
          .toLowerCase null
          .indexOf 'bitbucket') >= 0
        req.params.message_id = 1
        req.params.text = '/' + req.header 'X-Event-Key'
        req.params.chat = {}
        req.params.chat.id = 1
        req.params.from = {}
        req.params.from.id = 1
  ]
