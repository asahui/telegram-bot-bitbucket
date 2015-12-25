AsciiTable = require('ascii-table')

exports.parseNotification = (msg) ->
  try
    push = msg.push
    repository = msg.repository
    actor = msg.actor
    changes = push.changes
    commits = []
    commits.push commit for commit in change.commits for change in changes
    commit_num = if commits.length > 1 then "#{commits.length} commits" else "a commit"
    table = new AsciiTable()
    table.setHeading('Author', 'Commit', 'Message')
    trimMessage = (message) ->
        m = row.message.split('\n')[0]
        message = if m.length <= 60 then m else m.substr(0, 57) + '...'
    for row in commits
      table.addRow row.author.user.display_name, row.hash.substring(0, 7), trimMessage row
    tableStr = table.toString()
    for row in commits
      tableStr = tableStr.replace row.hash.substr(0, 7),"[#{row.hash.substr(0,7)}](#{row.links.html.href})"
    #table.removeBorder()
    "*#{actor.display_name}* pushed #{commit_num} to the repository:\n" +
    "[#{repository.full_name}](#{repository.links.html.href})\n" +
    "#{tableStr}\n"
  catch err
    console.log err
    "#{err}"