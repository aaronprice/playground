# Zayzoon


## Setup

### Prerequisites
- Docker and Docker Compose
- Node.js and Yarn (for asset compilation)

### Development Environment

1. **Start the development environment:**
   ```bash
   docker compose up
   ```

2. **Access the application:**
   - Open http://localhost:3100 in your browser

3. **View logs:**
   ```bash
   docker compose logs -f web
   ```

4. **Stop the environment:**
   ```bash
   docker compose down
   ```

### Test Environment

1. **Start the test environment:**
   ```bash
   docker compose -f docker-compose.test.yml up
   ```

2. **Access the test application:**
   - Open http://localhost:3101 in your browser

3. **Run specs:**
   ```bash
   # Run all specs
   docker compose -f docker-compose.test.yml exec web bundle exec rspec

   # Run specific spec file
   docker compose -f docker-compose.test.yml exec web bundle exec rspec spec/models/user_spec.rb

   # Run specs with documentation format
   docker compose -f docker-compose.test.yml exec web bundle exec rspec --format documentation

   # Run specs and watch for changes
   docker compose -f docker-compose.test.yml exec web bundle exec rspec --watch
   ```

4. **Stop the test environment:**
   ```bash
   docker compose -f docker-compose.test.yml down
   ```

### Environment Configuration

The application uses a hierarchical environment configuration:

- **`.env`** - Base configuration (defaults)
- **`.env.development`** - Development-specific overrides
- **`.env.test`** - Test-specific overrides

### Database Management

**Create and migrate the development database:**
```bash
docker compose exec web bundle exec rails db:create db:migrate
```

**Create and migrate the test database:**
```bash
docker compose -f docker-compose.test.yml exec web bundle exec rails db:create db:migrate
```

**Reset development database:**
```bash
docker compose exec web bundle exec rails db:reset
```

## Testing with RSpec

This project uses RSpec for testing instead of minitest. All specs are located in the `spec/` directory.

### Running Specs

**Run all specs:**
```bash
docker compose -f docker-compose.test.yml exec web bundle exec rspec
```

**Run specific spec file:**
```bash
docker compose -f docker-compose.test.yml exec web bundle exec rspec spec/models/user_spec.rb
```

**Run specs in a specific directory:**
```bash
docker compose -f docker-compose.test.yml exec web bundle exec rspec spec/models/
docker compose -f docker-compose.test.yml exec web bundle exec rspec spec/controllers/
```

**Run specs with different formats:**
```bash
# Documentation format (shows test descriptions)
docker compose -f docker-compose.test.yml exec web bundle exec rspec --format documentation

# Progress format (shows dots for passing tests)
docker compose -f docker-compose.test.yml exec web bundle exec rspec --format progress

# JSON format (for CI/CD integration)
docker compose -f docker-compose.test.yml exec web bundle exec rspec --format json
```

**Run specs with additional options:**
```bash
# Run only failing specs
docker compose -f docker-compose.test.yml exec web bundle exec rspec --only-failures

# Run specs and watch for changes
docker compose -f docker-compose.test.yml exec web bundle exec rspec --watch

# Run specs with random seed
docker compose -f docker-compose.test.yml exec web bundle exec rspec --seed 12345
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


