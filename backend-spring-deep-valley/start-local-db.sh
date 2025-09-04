#!/bin/bash
echo "🐳 Starting PostgreSQL for local development..."
docker-compose up -d postgres

echo "⏳ Waiting for PostgreSQL to be ready..."
until docker-compose exec postgres pg_isready -U deep-valley-user -d deep-valley-db > /dev/null 2>&1; do
  sleep 1
done

echo "✅ PostgreSQL is ready!"
echo "📋 Database connection details:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: deep-valley-db"
echo "   Username: deep-valley-user"
echo "   Password: deep-valley-pwd"
echo ""
echo "🚀 To run the application with local profile:"
echo "   ./gradlew bootRun --args='--spring.profiles.active=local'"