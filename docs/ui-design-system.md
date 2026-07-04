# UI Design System

Last updated: 2026-07-04

## Direction

- Product tone: professional modern helpdesk SaaS
- Primary palette: deep navy, indigo, cyan
- Theme model: Material 3 with a single typography family
- Motion target: 160-280 ms with subtle scale and elevation changes
- Spacing system: 4/8-point scale

## Tokens

### Color

- Brand navy: `#10233F`
- Brand navy deep: `#091426`
- Brand indigo: `#345CFF`
- Brand cyan: `#16B7D9`
- Success: `#169B6B`
- Warning: `#E59A1A`
- Danger: `#D84D3F`
- Info: `#2A83F7`

### Surface

- Light background: `#F4F7FB`
- Light surface: `#FFFFFF`
- Light muted surface: `#EDF2F9`
- Dark background: `#081221`
- Dark surface: `#0F1B30`
- Dark muted surface: `#17263E`

### Typography

- Family: Plus Jakarta Sans
- Display/headline: 20-32 px, weight `700`
- Title: 14-18 px, weight `600-700`
- Body: 12-16 px, weight `500`
- Label: 11-14 px, weight `700`

### Spacing and shape

- Base steps: `4, 8, 12, 14, 16, 20, 24, 32, 40, 48, 64`
- Radius: `8, 12, 16, 20, 24`
- Button heights: `40, 48, 56`
- Elevation: `0, 2, 6, 12`

## Foundations

- Theme source: [app_theme.dart](/D:/proyek/uts_s4/lib/shared/theme/app_theme.dart)
- Color tokens: [app_colors.dart](/D:/proyek/uts_s4/lib/core/constants/app_colors.dart)
- Dimension tokens: [app_dimensions.dart](/D:/proyek/uts_s4/lib/core/constants/app_dimensions.dart)

## Reusable Components

- Buttons: [app_button.dart](/D:/proyek/uts_s4/lib/shared/widgets/app_button.dart)
  Variants: `primary`, `secondary`, `ghost`, `danger`
- Text input: [app_text_field.dart](/D:/proyek/uts_s4/lib/shared/widgets/app_text_field.dart)
- Surface card: [app_surface_card.dart](/D:/proyek/uts_s4/lib/shared/widgets/app_surface_card.dart)
- Status chip: [app_status_chip.dart](/D:/proyek/uts_s4/lib/shared/widgets/app_status_chip.dart)
- Empty/error/offline/confirmation state: [empty_state_widget.dart](/D:/proyek/uts_s4/lib/shared/widgets/empty_state_widget.dart)
- Loading skeleton: [loading_widget.dart](/D:/proyek/uts_s4/lib/shared/widgets/loading_widget.dart)
- Offline banner: [connectivity_banner_widget.dart](/D:/proyek/uts_s4/lib/shared/widgets/connectivity_banner_widget.dart)

## Usage Rules

- Use semantic colors only for status communication; never overload status colors as brand backgrounds.
- Prefer `AppButton` and `AppTextField` over raw Material widgets in feature screens.
- Keep cards on `radiusMD` and chips on `radiusFull`.
- Use `EmptyStateWidget.offline()` for retryable network failures and `EmptyStateWidget.error()` for non-network data failures.
- Keep loading feedback finite for local actions; reserve persistent animated states for active network or initialization work.
- Preserve contrast parity between light and dark modes when introducing new components.

## Screen-State Baseline

- Loading: `LoadingWidget`, `ShimmerCard`, `FullPageLoader`
- Empty: `EmptyStateWidget.emptyTickets`, `.emptySearch`, `.emptyNotifications`, `.emptyHistory`
- Error: `EmptyStateWidget.error`
- Offline: `EmptyStateWidget.offline` and `ConnectivityBannerWidget`
- Confirmation: `EmptyStateWidget.confirmation`

## Pending Adoption

- Migrate legacy screens with hard-coded colors to the token set progressively.
- Standardize raw `Card`, `Chip`, and `SnackBar` usages in feature pages onto the shared system during Workstream 3.
