# Tekeraheza Mobile

A Flutter-based mobile application for the Tekeraheza LPG Gas Distribution Management System. This app serves both Customers and Delivery personnel.

## Features

### Customer Portal
- Browse LPG Gas products
- Place and track orders
- Payment integration
- Order history

### Delivery Portal
- View assigned deliveries
- GPS navigation to customer location
- Update delivery status (Picked up, Delivered, Failed)
- Delivery history and earnings

## Getting Started

1.  **Prerequisites**: Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
2.  **Clone the repo**: `git clone <repo-url>`
3.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Configuration**:
    Update the backend base URL in `lib/core/api/api_constants.dart`.
5.  **Run the app**:
    ```bash
    flutter run
    ```

## Project Structure

- `lib/core`: Core utilities, API services, and theme configurations.
- `lib/features/customer`: Customer-specific logic and UI.
- `lib/features/delivery`: Delivery-specific logic and UI.
- `lib/shared`: Shared widgets and components used across both portals.
