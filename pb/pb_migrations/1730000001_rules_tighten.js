/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const bookings = app.findCollectionByNameOrId("bookings");
  bookings.createRule = 'user = @request.auth.id';
  app.save(bookings);

  const users = app.findCollectionByNameOrId("users");
  users.createRule =
    '@request.body.role = "client" && (@request.auth.id = "" || @request.auth.role = "admin")';
  app.save(users);
}, (app) => {});
