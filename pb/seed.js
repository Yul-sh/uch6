const http = require('http');

const BASE = 'http://127.0.0.1:8090/api';

function request(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const url = new URL(BASE + path);
    const req = http.request(
      {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname + url.search,
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: token } : {}),
          ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
        },
      },
      (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          let parsed = raw;
          try {
            parsed = raw ? JSON.parse(raw) : null;
          } catch (_) {}
          if (res.statusCode >= 400) {
            reject(new Error(`${method} ${path} -> ${res.statusCode} ${raw}`));
          } else {
            resolve(parsed);
          }
        });
      },
    );
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function findOne(token, col, filter) {
  const res = await request(
    'GET',
    `/collections/${col}/records?perPage=1&filter=${encodeURIComponent(filter)}`,
    null,
    token,
  );
  return (res.items && res.items[0]) || null;
}

async function ensure(token, col, filter, body) {
  const existing = await findOne(token, col, filter);
  if (existing) return existing;
  return request('POST', `/collections/${col}/records`, body, token);
}

async function main() {
  const auth = await request('POST', '/collections/_superusers/auth-with-password', {
    identity: 'admin@flyy.local',
    password: 'Admin123!Admin123!',
  });
  const token = auth.token;

  for (const u of [
    {
      email: 'client@flyy.local',
      password: 'Pass123!',
      passwordConfirm: 'Pass123!',
      displayName: 'Анна Клиент',
      role: 'client',
      emailVisibility: true,
    },
    {
      email: 'manager@flyy.local',
      password: 'Pass123!',
      passwordConfirm: 'Pass123!',
      displayName: 'Игорь Менеджер',
      role: 'manager',
      emailVisibility: true,
    },
    {
      email: 'admin@flyy.local',
      password: 'Pass123!',
      passwordConfirm: 'Pass123!',
      displayName: 'Ольга Админ',
      role: 'admin',
      emailVisibility: true,
    },
  ]) {
    try {
      await request('POST', '/collections/users/records', u, token);
      console.log('user', u.email);
    } catch (_) {
      console.log('user skip', u.email);
    }
  }

  const d1 = await ensure(token, 'destinations', 'name="Шамони"', {
    name: 'Шамони',
    country: 'Франция',
    isDeleted: false,
  });
  const d2 = await ensure(token, 'destinations', 'name="Барселона"', {
    name: 'Барселона',
    country: 'Испания',
    isDeleted: false,
  });
  const d3 = await ensure(token, 'destinations', 'name="Анталья"', {
    name: 'Анталья',
    country: 'Турция',
    isDeleted: false,
  });
  const d4 = await ensure(token, 'destinations', 'name="Сочи"', {
    name: 'Сочи',
    country: 'Россия',
    isDeleted: false,
  });
  const d5 = await ensure(token, 'destinations', 'name="Прага"', {
    name: 'Прага',
    country: 'Чехия',
    isDeleted: false,
  });

  const c1 = await ensure(token, 'categories', 'name="Горнолыжный"', {
    name: 'Горнолыжный',
    isDeleted: false,
  });
  const c2 = await ensure(token, 'categories', 'name="Пляжный"', {
    name: 'Пляжный',
    isDeleted: false,
  });
  const c3 = await ensure(token, 'categories', 'name="Экскурсионный"', {
    name: 'Экскурсионный',
    isDeleted: false,
  });
  const c4 = await ensure(token, 'categories', 'name="Семейный"', {
    name: 'Семейный',
    isDeleted: false,
  });

  const h1 = await ensure(token, 'hotels', 'name="Альпийский домик"', {
    name: 'Альпийский домик',
    country: 'Франция',
    city: 'Шамони',
    stars: 4,
    isDeleted: false,
  });
  const h2 = await ensure(token, 'hotels', 'name="Морской бриз"', {
    name: 'Морской бриз',
    country: 'Испания',
    city: 'Барселона',
    stars: 5,
    isDeleted: false,
  });
  const h3 = await ensure(token, 'hotels', 'name="Солнечный курорт"', {
    name: 'Солнечный курорт',
    country: 'Турция',
    city: 'Анталья',
    stars: 5,
    isDeleted: false,
  });
  const h4 = await ensure(token, 'hotels', 'name="Роза Хутор"', {
    name: 'Роза Хутор',
    country: 'Россия',
    city: 'Сочи',
    stars: 5,
    isDeleted: false,
  });
  const h5 = await ensure(token, 'hotels', 'name="Староместская площадь"', {
    name: 'Староместская площадь',
    country: 'Чехия',
    city: 'Прага',
    stars: 4,
    isDeleted: false,
  });

  const tours = [
    {
      title: 'Альпы — Шамони',
      code: 'FR-2024-005',
      year: 2025,
      durationDays: 8,
      price: 156000,
      seatsTotal: 16,
      seatsAvailable: 12,
      destination: d1.id,
      categories: [c1.id],
      hotels: [h1.id],
    },
    {
      title: 'Вкус Барселоны',
      code: 'ES-2025-008',
      year: 2025,
      durationDays: 6,
      price: 98000,
      seatsTotal: 20,
      seatsAvailable: 15,
      destination: d2.id,
      categories: [c3.id],
      hotels: [h2.id],
    },
    {
      title: 'Солнце Антальи',
      code: 'TR-2025-001',
      year: 2025,
      durationDays: 10,
      price: 72000,
      seatsTotal: 30,
      seatsAvailable: 22,
      destination: d3.id,
      categories: [c2.id],
      hotels: [h3.id],
    },
    {
      title: 'Трек по Пиренеям',
      code: 'ES-2025-011',
      year: 2026,
      durationDays: 7,
      price: 110000,
      seatsTotal: 12,
      seatsAvailable: 12,
      destination: d2.id,
      categories: [c1.id, c3.id],
      hotels: [h2.id],
    },
    {
      title: 'Ликийская тропа',
      code: 'TR-2026-003',
      year: 2026,
      durationDays: 9,
      price: 89000,
      seatsTotal: 18,
      seatsAvailable: 10,
      destination: d3.id,
      categories: [c3.id],
      hotels: [h3.id],
    },
    {
      title: 'Сочи у моря',
      code: 'RU-2025-014',
      year: 2025,
      durationDays: 7,
      price: 65000,
      seatsTotal: 25,
      seatsAvailable: 18,
      destination: d4.id,
      categories: [c2.id, c4.id],
      hotels: [h4.id],
    },
    {
      title: 'Горный Сочи зимой',
      code: 'RU-2026-002',
      year: 2026,
      durationDays: 5,
      price: 78000,
      seatsTotal: 20,
      seatsAvailable: 14,
      destination: d4.id,
      categories: [c1.id],
      hotels: [h4.id],
    },
    {
      title: 'Прага на выходные',
      code: 'CZ-2025-009',
      year: 2025,
      durationDays: 4,
      price: 54000,
      seatsTotal: 22,
      seatsAvailable: 16,
      destination: d5.id,
      categories: [c3.id],
      hotels: [h5.id],
    },
    {
      title: 'Семейный отдых в Анталье',
      code: 'TR-2025-020',
      year: 2025,
      durationDays: 12,
      price: 95000,
      seatsTotal: 28,
      seatsAvailable: 20,
      destination: d3.id,
      categories: [c2.id, c4.id],
      hotels: [h3.id],
    },
    {
      title: 'Барселона с детьми',
      code: 'ES-2026-004',
      year: 2026,
      durationDays: 8,
      price: 102000,
      seatsTotal: 18,
      seatsAvailable: 11,
      destination: d2.id,
      categories: [c3.id, c4.id],
      hotels: [h2.id],
    },
    {
      title: 'Новогодний Шамони',
      code: 'FR-2025-031',
      year: 2025,
      durationDays: 6,
      price: 189000,
      seatsTotal: 14,
      seatsAvailable: 8,
      destination: d1.id,
      categories: [c1.id, c4.id],
      hotels: [h1.id],
    },
    {
      title: 'Пражские замки',
      code: 'CZ-2026-007',
      year: 2026,
      durationDays: 5,
      price: 61000,
      seatsTotal: 16,
      seatsAvailable: 16,
      destination: d5.id,
      categories: [c3.id],
      hotels: [h5.id],
    },
  ];

  for (const t of tours) {
    const body = { ...t, isDeleted: false };
    const existing = await findOne(token, 'tours', `code="${t.code}"`);
    if (existing) {
      console.log('tour skip', t.code);
      continue;
    }
    await request('POST', '/collections/tours/records', body, token);
    console.log('tour', t.code, t.title);
  }

  const clients = [
    {
      firstName: 'Мария',
      lastName: 'Иванова',
      email: 'maria@example.com',
      phone: '+79001112233',
      card: 'LY-10001',
      status: 'active',
      issuedAt: '2024-01-15 00:00:00.000Z',
      expiresAt: '2027-01-15 00:00:00.000Z',
    },
    {
      firstName: 'Пётр',
      lastName: 'Сидоров',
      email: 'petr@example.com',
      phone: '+79005556677',
      card: 'LY-10002',
      status: 'active',
      issuedAt: '2025-03-01 00:00:00.000Z',
    },
    {
      firstName: 'Елена',
      lastName: 'Козлова',
      email: 'elena.kozlova@example.com',
      phone: '+79001234567',
      card: 'LY-10003',
      status: 'active',
      issuedAt: '2024-06-01 00:00:00.000Z',
      expiresAt: '2027-06-01 00:00:00.000Z',
    },
    {
      firstName: 'Алексей',
      lastName: 'Новиков',
      email: 'alex.novikov@example.com',
      phone: '+79007654321',
      card: 'LY-10004',
      status: 'active',
      issuedAt: '2025-01-10 00:00:00.000Z',
    },
    {
      firstName: 'Ольга',
      lastName: 'Морозова',
      email: 'olga.morozova@example.com',
      phone: '+79009876543',
      card: 'LY-10005',
      status: 'expired',
      issuedAt: '2022-05-20 00:00:00.000Z',
      expiresAt: '2025-05-20 00:00:00.000Z',
    },
    {
      firstName: 'Дмитрий',
      lastName: 'Волков',
      email: 'dmitry.volkov@example.com',
      phone: '+79003334455',
      card: 'LY-10006',
      status: 'active',
      issuedAt: '2024-11-03 00:00:00.000Z',
      expiresAt: '2027-11-03 00:00:00.000Z',
    },
    {
      firstName: 'Анна',
      lastName: 'Соколова',
      email: 'anna.sokolova@example.com',
      phone: '+79004445566',
      card: 'LY-10007',
      status: 'active',
      issuedAt: '2025-02-14 00:00:00.000Z',
    },
    {
      firstName: 'Игорь',
      lastName: 'Лебедев',
      email: 'igor.lebedev@example.com',
      phone: '+79006667788',
      card: 'LY-10008',
      status: 'active',
      issuedAt: '2023-09-01 00:00:00.000Z',
      expiresAt: '2026-09-01 00:00:00.000Z',
    },
    {
      firstName: 'Наталья',
      lastName: 'Павлова',
      email: 'natalya.pavlova@example.com',
      phone: '+79007778899',
      card: 'LY-10009',
      status: 'active',
      issuedAt: '2024-08-22 00:00:00.000Z',
    },
    {
      firstName: 'Сергей',
      lastName: 'Фёдоров',
      email: 'sergey.fedorov@example.com',
      phone: '+79008889900',
      card: 'LY-10010',
      status: 'expired',
      issuedAt: '2021-12-01 00:00:00.000Z',
      expiresAt: '2024-12-01 00:00:00.000Z',
    },
  ];

  for (const c of clients) {
    const client = await ensure(token, 'clients', `email="${c.email}"`, {
      firstName: c.firstName,
      lastName: c.lastName,
      email: c.email,
      phone: c.phone,
      isDeleted: false,
    });
    await ensure(token, 'loyalty_cards', `number="${c.card}"`, {
      number: c.card,
      status: c.status,
      issuedAt: c.issuedAt,
      ...(c.expiresAt ? { expiresAt: c.expiresAt } : {}),
      client: client.id,
    });
    console.log('client', c.lastName, c.firstName);
  }

  console.log('SEED DONE');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
