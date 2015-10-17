json.roomUser do
  json.id @room_user.id
  json.name @room_user.name
  json.avatar @room_user.avatar
  json.room_id @room_user.room_id
  json.gender @room_user.gender
  json.age @room_user.age
  json.location @room_user.location
end