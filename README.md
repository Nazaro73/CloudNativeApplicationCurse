# Gym Management System

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=Nazaro73_CloudNativeApplicationCurse&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Nazaro73_CloudNativeApplicationCurse)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=Nazaro73_CloudNativeApplicationCurse&metric=bugs)](https://sonarcloud.io/summary/new_code?id=Nazaro73_CloudNativeApplicationCurse)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=Nazaro73_CloudNativeApplicationCurse&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=Nazaro73_CloudNativeApplicationCurse)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=Nazaro73_CloudNativeApplicationCurse&metric=coverage)](https://sonarcloud.io/summary/new_code?id=Nazaro73_CloudNativeApplicationCurse)

A complete fullstack gym management application built with modern web technologies.

## Features

### User Features
- **User Dashboard**: View stats, billing, and recent bookings
- **Class Booking**: Book and cancel fitness classes
- **Subscription Management**: View subscription details and billing
- **Profile Management**: Update personal information

### Admin Features
- **Admin Dashboard**: Overview of gym statistics and revenue
- **User Management**: CRUD operations for users
- **Class Management**: Create, update, and delete fitness classes
- **Booking Management**: View and manage all bookings
- **Subscription Management**: Manage user subscriptions

### Business Logic
- **Capacity Management**: Classes have maximum capacity limits
- **Time Conflict Prevention**: Users cannot book overlapping classes
- **Cancellation Policy**: 2-hour cancellation policy (late cancellations become no-shows)
- **Billing System**: Dynamic pricing with no-show penalties
- **Subscription Types**: Standard (€30), Premium (€50), Student (€20)

## Tech Stack

### Backend
- **Node.js** with Express.js
- **Prisma** ORM with PostgreSQL
- **RESTful API** with proper error handling
- **MVC Architecture** with repositories pattern

### Frontend
- **Vue.js 3** with Composition API
- **Pinia** for state management
- **Vue Router** with navigation guards
- **Responsive CSS** styling

### DevOps
- **Docker** containerization
- **Docker Compose** for orchestration
- **PostgreSQL** database
- **Nginx** for frontend serving

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd gym-management-system
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file if needed (default values should work for development).

3. **Start the application**
   ```bash
   docker-compose up --build
   ```

4. **Access the application**
   - Frontend: http://localhost:8080
   - Backend API: http://localhost:3000
   - Database: localhost:5432

### Default Login Credentials

The application comes with seeded test data:

**Admin User:**
- Email: admin@gym.com
- Password: admin123
- Role: ADMIN

**Regular Users:**
- Email: john.doe@email.com
- Email: jane.smith@email.com  
- Email: mike.wilson@email.com
- Password: password123 (for all users)

## Project Structure

```
gym-management-system/
├── backend/
│   ├── src/
│   │   ├── controllers/     # Request handlers
│   │   ├── services/        # Business logic
│   │   ├── repositories/    # Data access layer
│   │   ├── routes/          # API routes
│   │   └── prisma/          # Database schema and client
│   ├── seed/                # Database seeding
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── views/           # Vue components/pages
│   │   ├── services/        # API communication
│   │   ├── store/           # Pinia stores
│   │   └── router/          # Vue router
│   ├── Dockerfile
│   └── nginx.conf
└── docker-compose.yml
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login

### Users
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Classes
- `GET /api/classes` - Get all classes
- `GET /api/classes/:id` - Get class by ID
- `POST /api/classes` - Create class
- `PUT /api/classes/:id` - Update class
- `DELETE /api/classes/:id` - Delete class

### Bookings
- `GET /api/bookings` - Get all bookings
- `GET /api/bookings/user/:userId` - Get user bookings
- `POST /api/bookings` - Create booking
- `PUT /api/bookings/:id/cancel` - Cancel booking
- `DELETE /api/bookings/:id` - Delete booking

### Subscriptions
- `GET /api/subscriptions` - Get all subscriptions
- `GET /api/subscriptions/user/:userId` - Get user subscription
- `POST /api/subscriptions` - Create subscription
- `PUT /api/subscriptions/:id` - Update subscription

### Dashboard
- `GET /api/dashboard/user/:userId` - Get user dashboard
- `GET /api/dashboard/admin` - Get admin dashboard

## Development

### Local Development Setup

1. **Backend Development**
   ```bash
   cd backend
   npm install
   npm run dev
   ```

2. **Frontend Development**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

3. **Database Setup**
   ```bash
   cd backend
   npx prisma migrate dev
   npm run seed
   ```

### Database Management

- **View Database**: `npx prisma studio`
- **Reset Database**: `npx prisma db reset`
- **Generate Client**: `npx prisma generate`
- **Run Migrations**: `npx prisma migrate deploy`

### Useful Commands

```bash
# Stop all containers
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Rebuild specific service
docker-compose up --build [service-name]

# Access database
docker exec -it gym_db psql -U postgres -d gym_management
```

## Features in Detail

### Subscription System
- **STANDARD**: €30/month, €5 per no-show
- **PREMIUM**: €50/month, €3 per no-show  
- **ETUDIANT**: €20/month, €7 per no-show

### Booking Rules
- Users can only book future classes
- Maximum capacity per class is enforced
- No double-booking at the same time slot
- 2-hour cancellation policy

### Admin Dashboard
- Total users and active subscriptions
- Booking statistics (confirmed, no-show, cancelled)
- Monthly revenue calculations
- User management tools

### User Dashboard
- Personal statistics and activity
- Current subscription details
- Monthly billing with no-show penalties
- Recent booking history

## Deploiement Blue/Green

Le projet utilise une strategie de deploiement blue/green pour assurer zero downtime.

### Architecture

```
                    ┌─────────────────┐
                    │     Client      │
                    └────────┬────────┘
                             │ :80
                    ┌────────▼────────┐
                    │  Reverse Proxy  │
                    │     (Nginx)     │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │      BLUE       │           │      GREEN      │
     │  (version N)    │           │  (version N+1)  │
     └────────┬────────┘           └────────┬────────┘
              │                             │
              └──────────────┬──────────────┘
                             │
                    ┌────────▼────────┐
                    │    PostgreSQL   │
                    └─────────────────┘
```

### Principe

- **Blue** = version actuellement en production
- **Green** = nouvelle version a deployer (ou inverse)
- Le reverse proxy route le trafic vers la version active
- Bascule instantanee sans interruption de service
- Rollback immediat en cas de probleme

### Pipeline CI/CD

```
lint -> build -> test -> sonarcloud -> docker -> deploy-blue-green
```

### Deroulement d'un deploiement

1. **Build & Push** : Construction et publication des images sur GHCR
2. **Detection** : Lecture de la couleur active actuelle
3. **Deploiement** : Lancement de la nouvelle version sur la couleur inactive
4. **Health check** : Verification que la nouvelle version repond
5. **Bascule** : Mise a jour du reverse proxy vers la nouvelle couleur
6. **Disponible** : Rollback possible vers l'ancienne version

### Fichiers Docker Compose

| Fichier | Description |
|---------|-------------|
| `docker-compose.base.yml` | PostgreSQL + Reverse Proxy |
| `docker-compose.blue.yml` | Backend + Frontend (blue) |
| `docker-compose.green.yml` | Backend + Frontend (green) |

### Commandes utiles

**Deployer manuellement (blue/green automatique) :**
```powershell
.\scripts\deploy-blue-green.ps1 -ImageTag "latest"
```

**Basculer manuellement vers une couleur :**
```powershell
.\scripts\switch-color.ps1 -Color blue   # ou green
```

**Verifier la couleur active :**
```bash
curl http://localhost/status
```

### Pre-requis

- **Runner local actif** : Le runner GitHub Actions self-hosted doit etre demarre
- **Secrets configures** : `GITHUB_TOKEN` pour l'acces au registre GHCR
- **Docker Desktop** : Doit etre lance sur la machine du runner
- **Port 80 disponible** : Pour le reverse proxy

### Branches avec deploiement actif

- `main` - Branche principale de production
- `develop` - Branche de developpement
- `feature/*` - Branches de fonctionnalites

### Rollback

En cas de probleme avec la nouvelle version :

```powershell
# Revenir a la version precedente
.\scripts\switch-color.ps1 -Color blue  # ou green selon le cas
```

Le rollback est instantane (< 1 seconde).

### Idempotence

Le deploiement est idempotent :
- Peut etre execute plusieurs fois sans erreur
- Les volumes PostgreSQL sont preserves
- Les deux versions coexistent jusqu'a validation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support or questions, please open an issue in the repository.
