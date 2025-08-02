# Playground

## Scenario: Partner-submitted Purchase Order (PO) Ingestion
Context: B2B partners POST purchase orders into your system. Each partner has a 32-char token. The API validates payloads, looks up live pricing & availability from an external ERP, persists data across multiple models, returns a decorated JSON view of the PO, and kicks off async fulfillment.

```text
Endpoint
POST /api/v1/purchase_orders
Headers:
  Content-Type: application/json
  X-Api-Token: <32-char token>
Body:
{
  "external_po_id": "PO-12345",
  "customer": {
    "external_customer_ref": "CUST-998",
    "name": "Acme Inc",
    "email": "buy@acme.example",
    "shipping_address": { "line1":"1 Main", "city":"NYC", "region":"NY", "postal_code":"10001", "country":"US" }
  },
  "lines": [
    { "sku":"SKU-001", "quantity":2 },
    { "sku":"SKU-002", "quantity":1 }
  ],
  "requested_ship_date": "2025-08-05",
  "currency": "USD"
}
```
External dependency: For each SKU, call your ERP’s HTTP API to fetch current price, tax code, and available-to-promise (ATP). E.g. GET https://erp.example/api/sku/SKU-001?currency=USD.

Async work: Reserve inventory and notify WMS asynchronously; also email partner upon allocation.


## Setup

### Prerequisites
- Docker and Docker Compose
- Node.js and Yarn (for asset compilation)
- dip (Docker development workflow tool)

### Dip Commands

This project uses [dip](https://github.com/bibendi/dip) to simplify Docker development workflows. Here are the most common commands:

**Development Environment:**
- `dip up` - Start all services
- `dip down` - Stop all services
- `dip restart` - Restart all services
- `dip status` - Show service status
- `dip logs [service]` - View service logs
- `dip shell` - Open shell in web container
- `dip psql` - Connect to PostgreSQL database

**Rails Commands:**
- `dip rails c` - Rails console
- `dip rails s` - Rails server
- `dip rails db:migrate` - Run migrations
- `dip rails db:seed` - Seed database
- `dip rails db:reset` - Reset database

**Testing:**
- `dip test` - Run all tests
- `dip test:up` - Start test environment
- `dip test:down` - Stop test environment
- `dip test:shell` - Open shell in test container
- `dip test:psql` - Connect to test database

**Provisioning:**
- `dip provision` - Full environment setup (down, build, up)
- `dip build` - Rebuild containers

### Development Environment

1. **Start the development environment:**
   ```bash
   dip up
   ```

2. **Access the application:**
   - Open http://localhost:3100 in your browser

3. **View logs:**
   ```bash
   dip logs web
   ```

4. **Stop the environment:**
   ```bash
   dip down
   ```

### Test Environment

1. **Start the test environment:**
   ```bash
   dip test:up
   ```

2. **Access the test application:**
   - Open http://localhost:3101 in your browser

3. **Run specs:**
   ```bash
   # Run all specs
   dip test

   # Run specific spec file
   dip test spec/models/user_spec.rb

   # Run specs with documentation format
   dip test --format documentation

   # Run specs and watch for changes
   dip test --watch
   ```

4. **Stop the test environment:**
   ```bash
   dip test:down
   ```

### Environment Configuration

The application uses a hierarchical environment configuration:

- **`.env`** - Base configuration (defaults)
- **`.env.development`** - Development-specific overrides
- **`.env.test`** - Test-specific overrides

### Database Management

**Create and migrate the development database:**
```bash
dip rails db:create db:migrate
```

**Create and migrate the test database:**
```bash
dip test:shell
# Then inside the test container:
bundle exec rails db:create db:migrate
```

**Reset development database:**
```bash
dip rails db:reset
```

## Testing with RSpec

This project uses RSpec for testing instead of minitest. All specs are located in the `spec/` directory.

### Running Specs

**Run all specs:**
```bash
dip test
```

**Run specific spec file:**
```bash
dip test spec/models/user_spec.rb
```

**Run specs in a specific directory:**
```bash
dip test spec/models/
dip test spec/controllers/
```

**Run specs with different formats:**
```bash
# Documentation format (shows test descriptions)
dip test --format documentation

# Progress format (shows dots for passing tests)
dip test --format progress

# JSON format (for CI/CD integration)
dip test --format json
```

**Run specs with additional options:**
```bash
# Run only failing specs
dip test --only-failures

# Run specs and watch for changes
dip test --watch

# Run specs with random seed
dip test --seed 12345
```

### Spec Organization

- `spec/models/` - Model specs
- `spec/controllers/` - Controller specs
- `spec/requests/` - Request specs
- `spec/system/` - System specs (integration tests)
- `spec/factories/` - FactoryBot factories
- `spec/support/` - Shared support files

### Writing Specs

Specs use RSpec's `describe` and `it` blocks for organization:

```ruby
RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end
  end
end
```

## Development Setup

Install Node.js dependencies:
```bash
brew install node
corepack enable
corepack prepare yarn --activate

yarn add -D esbuild
yarn add -D tailwindcss @tailwindcss/cli
```


