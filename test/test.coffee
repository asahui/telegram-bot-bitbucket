database = require '../database'
database.connect()
console.log('connected!')
database.create()
console.log('table created')

for i in [1..5]
  database.add("#{i}", "#{i} hint", 'xuhui')
  console.log "add #{i}|#{i} hint|xuhui"

database.search 'in', (rows) ->
  console.log(rows)
  
for i in [6..26]
  database.add("#{i}", "#{i} hint", 'xuhui')
  console.log "add #{i}|#{i} hint|xuhui"

database.list 1 , (rows) ->
  console.log(rows)

