/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // --- destinations ---
  const destinations = new Collection({
    name: "destinations",
    type: "base",
    listRule: '@request.auth.id != ""',
    viewRule: '@request.auth.id != ""',
    createRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    updateRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    deleteRule: '@request.auth.role = "admin"',
    fields: [
      { name: "name", type: "text", required: true, max: 80 },
      { name: "country", type: "text", required: true, max: 80 },
      { name: "isDeleted", type: "bool" },
    ],
  });
  app.save(destinations);

  // --- categories ---
  const categories = new Collection({
    name: "categories",
    type: "base",
    listRule: '@request.auth.id != ""',
    viewRule: '@request.auth.id != ""',
    createRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    updateRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    deleteRule: '@request.auth.role = "admin"',
    fields: [
      { name: "name", type: "text", required: true, max: 80 },
      { name: "isDeleted", type: "bool" },
    ],
  });
  app.save(categories);

  // --- hotels ---
  const hotels = new Collection({
    name: "hotels",
    type: "base",
    listRule: '@request.auth.id != ""',
    viewRule: '@request.auth.id != ""',
    createRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    updateRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    deleteRule: '@request.auth.role = "admin"',
    fields: [
      { name: "name", type: "text", required: true, max: 80 },
      { name: "country", type: "text", required: true, max: 80 },
      { name: "city", type: "text", required: true, max: 80 },
      { name: "stars", type: "number", required: true, min: 1, max: 5 },
      { name: "isDeleted", type: "bool" },
    ],
  });
  app.save(hotels);

  // --- tours (M:N categories, hotels; 1:N destination) ---
  const tours = new Collection({
    name: "tours",
    type: "base",
    listRule: '@request.auth.id != ""',
    viewRule: '@request.auth.id != ""',
    createRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    updateRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    deleteRule: '@request.auth.role = "admin"',
    fields: [
      { name: "title", type: "text", required: true, max: 120 },
      { name: "code", type: "text", required: true, max: 32 },
      { name: "year", type: "number", required: true, min: 2020, max: 2035 },
      { name: "durationDays", type: "number", required: true, min: 1, max: 60 },
      { name: "price", type: "number", required: true, min: 0 },
      { name: "seatsTotal", type: "number", required: true, min: 1 },
      { name: "seatsAvailable", type: "number", required: true, min: 0 },
      {
        name: "destination",
        type: "relation",
        required: true,
        collectionId: destinations.id,
        maxSelect: 1,
      },
      {
        name: "categories",
        type: "relation",
        required: false,
        collectionId: categories.id,
        maxSelect: 20,
      },
      {
        name: "hotels",
        type: "relation",
        required: false,
        collectionId: hotels.id,
        maxSelect: 20,
      },
      { name: "isDeleted", type: "bool" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_tours_code ON tours (code)",
    ],
  });
  app.save(tours);

  // --- clients ---
  const clients = new Collection({
    name: "clients",
    type: "base",
    listRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    viewRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    createRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    updateRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    deleteRule: '@request.auth.role = "admin"',
    fields: [
      { name: "firstName", type: "text", required: true, max: 60 },
      { name: "lastName", type: "text", required: true, max: 60 },
      { name: "email", type: "email", required: true },
      { name: "phone", type: "text", required: false, max: 30 },
      { name: "isDeleted", type: "bool" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_clients_email ON clients (email)",
    ],
  });
  app.save(clients);

  // --- loyalty_cards 1:1 with client ---
  const loyaltyCards = new Collection({
    name: "loyalty_cards",
    type: "base",
    listRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    viewRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    createRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    updateRule: '@request.auth.role = "manager" || @request.auth.role = "admin"',
    deleteRule: '@request.auth.role = "admin"',
    fields: [
      { name: "number", type: "text", required: true, max: 32 },
      { name: "status", type: "text", required: true, max: 20 },
      { name: "issuedAt", type: "date", required: true },
      { name: "expiresAt", type: "date", required: false },
      {
        name: "client",
        type: "relation",
        required: true,
        collectionId: clients.id,
        maxSelect: 1,
      },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_loyalty_client ON loyalty_cards (client)",
      "CREATE UNIQUE INDEX idx_loyalty_number ON loyalty_cards (number)",
    ],
  });
  app.save(loyaltyCards);

  // --- bookings ---
  const usersCol = app.findCollectionByNameOrId("users");
  const bookings = new Collection({
    name: "bookings",
    type: "base",
    listRule:
      '@request.auth.role = "manager" || @request.auth.role = "admin" || user = @request.auth.id',
    viewRule:
      '@request.auth.role = "manager" || @request.auth.role = "admin" || user = @request.auth.id',
    createRule: '@request.auth.id != ""',
    updateRule:
      '@request.auth.role = "manager" || @request.auth.role = "admin" || (user = @request.auth.id && @request.auth.role = "client")',
    deleteRule: '@request.auth.role = "admin"',
    fields: [
      {
        name: "tour",
        type: "relation",
        required: true,
        collectionId: tours.id,
        maxSelect: 1,
      },
      {
        name: "user",
        type: "relation",
        required: true,
        collectionId: usersCol.id,
        maxSelect: 1,
      },
      { name: "tourTitle", type: "text", required: true, max: 120 },
      {
        name: "status",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["active", "closed"],
      },
      { name: "expiresAt", type: "date", required: true },
    ],
  });
  app.save(bookings);

  // users: role + displayName
  usersCol.fields.add(
    new Field({
      name: "role",
      type: "select",
      required: true,
      maxSelect: 1,
      values: ["client", "manager", "admin"],
    }),
  );
  usersCol.fields.add(
    new Field({
      name: "displayName",
      type: "text",
      required: true,
      max: 80,
    }),
  );
  usersCol.listRule = '@request.auth.role = "admin"';
  usersCol.viewRule = '@request.auth.id = id || @request.auth.role = "admin"';
  usersCol.createRule =
    '@request.body.role = "client" && (@request.auth.id = "" || @request.auth.role = "admin")';
  usersCol.updateRule = '@request.auth.role = "admin" || id = @request.auth.id';
  app.save(usersCol);
}, (app) => {
  for (const name of ["bookings", "loyalty_cards", "clients", "tours", "hotels", "categories", "destinations"]) {
    try {
      app.delete(app.findCollectionByNameOrId(name));
    } catch (_) {}
  }
});
