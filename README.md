# WishingShop

A fake shopping website built for development and testing practice. Based on the [Ruby on Rails tutorial](https://guides.rubyonrails.org/getting_started.html).

## Features

- **Feature 1** — Short description of the first key feature
- **Feature 2** — Short description of the second key feature
- **Feature 3** — Short description of the third key feature
- **Feature 4** — Short description of the fourth key feature

## Quick Start

### Prerequisites

- Ruby >= 3.2
- Rails >= 8.1
- [libvips](https://www.libvips.org/install.html)

### Installation

Create DB first time:

```bash
bin/rails db:create
```

### Basic Usage

```bash
bin/rails server
```

## Test Data

Seed the database with test users, 20 clothing products and a few subscribers (development and test only; seeds are skipped in production):

```bash
bin/rails db:migrate
bin/rails db:seed    # safe to run more than once
bin/rails db:reset   # start over: drop, recreate and seed
```

### Accounts

All accounts use the password `password`.

| Email | Role |
|---|---|
| `admin@example.com` | Admin |
| `alice@example.com` | User |
| `bob@example.com` | User |

Admins can create, edit and delete products (including stock), and have two extra pages in the header:

- **Users** (`/admin/users`): add, edit and delete standard users. Admin accounts aren't listed.
- **Subscribers** (`/admin/subscribers`): add, edit, move and remove back-in-stock subscribers.

Standard users and visitors can browse products and subscribe to out-of-stock items.

### Products

20 clothing items with cartoon images and generated descriptions. Stock is between 1 and 50, except for 3 items that are out of stock: **Hoodie**, **Puffer Vest** and **Cargo Shorts**.

Images are in `db/seeds/images/`. To change them, edit `script/generate_seed_images.rb` and run `ruby script/generate_seed_images.rb` (needs ImageMagick and libvips).

### Subscribers and emails

Each out-of-stock product has one subscriber:

| Product | Subscriber |
|---|---|
| Hoodie | `subscriber1@example.com` |
| Puffer Vest | `subscriber2@example.com` |
| Cargo Shorts | `subscriber3@example.com` |

In development, emails aren't sent. They're saved and can be read at [localhost:3000/letter_opener](http://localhost:3000/letter_opener). To test the back-in-stock email:

1. Log in as `admin@example.com`.
2. Edit one of the out-of-stock products and set its inventory above 0.
3. Open `/letter_opener` to see the email.

## License

Distributed under the MIT License. See `LICENSE` for more information.
