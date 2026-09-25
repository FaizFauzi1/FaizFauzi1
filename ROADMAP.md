# EventEase Master Roadmap

Implementation tracker for all 61 feature areas across 6 phases.
Status: `[x]` done · `[~]` partial · `[ ]` not started

---

## Phase 0 — Foundation

| Item | Status | Files |
|------|--------|-------|
| Country config (MY/SG/ID) | [x] | `lib/core/constants/country_config.dart` |
| Country DB migration | [x] | `supabase/migrations/20260823_add_country_to_users.sql` |
| CountryProvider | [x] | `lib/core/providers/country_provider.dart` |
| Country on signup | [x] | `lib/features/auth/presentation/sign_up_screen.dart` |
| Country in auth profiles | [x] | `lib/features/auth/data/auth_provider.dart` |
| Country in settings | [x] | `lib/features/customer/presentation/views/account/settings_screen.dart` |
| Currency ↔ country mapping | [x] | `lib/core/utils/currency_formatter.dart` |
| Country-aware regions | [x] | `lib/features/location/data/providers/location_provider.dart` |
| Design tokens | [x] | `lib/core/utils/ee_design_tokens.dart` |
| Premium theme (Inter/Playfair) | [x] | `lib/core/utils/app_theme.dart` |
| Shimmer loading | [x] | `lib/shared/widgets/design_system/shimmer_widgets.dart` |
| Empty/error/offline states | [x] | `lib/shared/widgets/design_system/state_widgets.dart` |
| Glass cards, pill badges, filter chips | [x] | `lib/shared/widgets/design_system/premium_widgets.dart` |
| Fix `/settings` and `/search` routes | [x] | `lib/core/utils/app_routes.dart` |

---

## Phase 1 — Premium Shared UX

| Item | Status | Files |
|------|--------|-------|
| Home hero + glass search | [x] | `lib/features/customer/presentation/widgets/home_hero_widget.dart` |
| Auth split-screen (signup) | [~] | `sign_up_screen.dart` (desktop split exists) |
| Auth glass card (login) | [ ] | `login_screen.dart` |
| Vendor card press animation | [x] | `PressableCard` in premium_widgets |
| Checkout premium breakdown | [x] | `checkout_screen.dart` + `payment_gateway_service.dart` |
| Remove checkout demo data | [x] | `checkout_screen.dart` |
| Vendor profile hero/gallery | [ ] | `vendor_profile_screen.dart` |
| Search filter chips | [x] | `FilterChipPill` widget (wire in search_screen) |
| Search shimmer | [ ] | `search_screen.dart` |

---

## Phase 2 — Core Marketplace Loop

| Item | Status | Files |
|------|--------|-------|
| Chat event context header | [x] | `lib/features/chat/presentation/widgets/chat_event_context_header.dart` |
| Anti-bypass detection | [x] | `lib/core/services/anti_bypass_service.dart` |
| Anti-bypass in chat | [x] | `lib/features/chat/data/providers/chat_provider.dart` |
| Proposal builder | [x] | `lib/features/quotes/presentation/proposal_builder_screen.dart` |
| Actionable notifications | [ ] | `notification_screen.dart` |
| Calendar sync (Google/Apple) | [ ] | — |
| 48-hour holds | [ ] | — |

Route: `/proposal-builder`

---

## Phase 3 — Vendor Growth

| Item | Status | Files |
|------|--------|-------|
| Kanban lead pipeline | [x] | `lib/features/vendor/presentation/views/vendor_lead_kanban_screen.dart` |
| Vendor analytics insights | [ ] | `vendor_analytics_screen.dart` |
| Finance currency wiring | [x] | `vendor_settings_screen_enhanced.dart` |
| Vendor onboarding country | [~] | `vendor_profile_provider.dart` (fields added) |
| Email campaign builder | [ ] | — |

Route: `/vendor-lead-kanban`, `/proposal-builder`

---

## Phase 4 — Customer Planning

| Item | Status | Files |
|------|--------|-------|
| Mood boards | [x] | `lib/features/mood_board/presentation/mood_board_screen.dart` |
| Budget manager | [~] | `budget_screen.dart` (exists, needs polish) |
| Guest list | [~] | `guest_list_screen.dart` (exists) |
| Planning dashboard | [~] | `planner_screen.dart`, `event_planning_hub_screen.dart` |
| Event timeline UI | [ ] | DB exists, UI incomplete |
| Seating planner drag-drop | [ ] | `seating_assignment_screen.dart` |

Route: `/mood-boards`, `/ai-matchmaker`

---

## Phase 5 — Differentiators

| Item | Status | Files |
|------|--------|-------|
| AI Matchmaker quiz | [x] | `lib/features/ai_matchmaker/presentation/ai_matchmaker_screen.dart` |
| Digital contracts + e-sign | [x] | `lib/features/contracts/presentation/contract_detail_screen.dart` |
| Photo delivery portal | [x] | `lib/features/photo_delivery/presentation/photo_delivery_portal_screen.dart` |
| Universal help center | [x] | `lib/shared/views/help_center_screen.dart` |
| Venue virtual tour | [ ] | — |
| QR photo wall (live) | [ ] | `photo_sharing_screen_fixed.dart` |
| Admin concierge | [ ] | — |
| Delight / confetti / haptics | [ ] | — |

Routes: `/contracts`, `/photo-delivery`, `/help-center`

---

## New Routes Added

```
/search              → SearchScreen
/settings            → SettingsScreen
/profile             → AccountScreen
/vendor-lead-kanban  → VendorLeadKanbanScreen
/proposal-builder    → ProposalBuilderScreen
/mood-boards         → MoodBoardScreen
/ai-matchmaker       → AiMatchmakerScreen
/contracts           → ContractDetailScreen
/photo-delivery      → PhotoDeliveryPortalScreen
/help-center         → HelpCenterScreen
/admin/anti-bypass   → AntiBypassDashboardScreen
/admin/revenue       → AdminRevenueDashboardScreen
/admin/churn         → AdminChurnDashboardScreen
/admin/broadcast     → AdminBroadcastScreen
/admin/dispute-detail → AdminDisputeDetailScreen
```

---

## Phase 8 — Admin Operations

| Item | Status | Files |
|------|--------|-------|
| User management | [~] | `user_guest_management_screen.dart`, `AdminUsersScreen` |
| Vendor management | [x] | `vendor_management_screen.dart` (10 tabs) |
| Customer management | [~] | Merged into Users & Guests |
| Booking management | [x] | `booking_service_management_screen.dart` |
| Payment management | [~] | `financial_management_screen.dart` |
| Subscription management | [~] | `modules/subscription_management_screen.dart` |
| Review moderation | [~] | `dispute_review_management_screen.dart` |
| Content moderation | [~] | `content_marketing_screen.dart` |
| Support tickets | [~] | `support_agent_dashboard.dart` |
| KYC / SSM / identity verification | [~] | Document Review tabs + `verifyDocument()` |
| Verification history | [x] | `vendor_verification_events` + `VerificationEventLogger` |
| Re-verification | [ ] | — |
| Anti-bypass dashboard | [x] | `anti_bypass_dashboard_screen.dart` |
| Phone/email/WhatsApp/payment detection | [x] | `AdminBypassProvider` + chat integration |
| Conversation flagging | [x] | `bypass_incidents` table + `BypassIncidentRecorder` |
| Warning system | [x] | `vendor_warnings` + `issueWarning()` |
| Repeat offender tracking | [x] | `repeat_offender_scores` + offenders tab |
| Dispute creation | [x] | `AdminDisputesProvider.createDispute()` |
| Evidence timeline | [x] | `admin_dispute_detail_screen.dart` |
| Admin decision + refund workflow | [x] | `resolveDispute()` + `admin_refunds` |
| Login as Vendor | [x] | `system_security_screen.dart` + `AdminImpersonationService` |
| Impersonation audit log | [x] | `admin_impersonation_log` table |
| Return to admin flow | [x] | `endImpersonation()` button |

DB: `supabase/migrations/20260823_admin_phase8_phase9.sql`

---

## Phase 9 — Admin Revenue & Growth

| Item | Status | Files |
|------|--------|-------|
| Revenue dashboard | [x] | `admin_revenue_dashboard_screen.dart` |
| Commission revenue | [x] | `AdminRevenueProvider` + country view |
| Subscription revenue | [x] | `_fetchSubscriptionRevenue()` |
| Sponsored listings | [x] | `sponsored_listing_campaigns` + revenue tab |
| Payment fees / refunds / payouts | [x] | Overview metrics |
| Country-level revenue | [x] | `admin_revenue_by_country` view |
| Promotions admin | [x] | `admin_promotions` + promotions tab |
| Broadcast center | [x] | `admin_broadcast_screen.dart` |
| Scheduled announcements | [x] | `scheduleAnnouncement()` with `scheduled_at` |
| Audience targeting | [x] | all/customers/vendors/tier_premium |
| Churn / at-risk vendors | [x] | `admin_churn_dashboard_screen.dart` |
| Retention actions | [x] | Profile boost, outreach, free month |
| Outreach tracking | [x] | `outreach_status` on churn snapshots |

Providers: `AdminRevenueProvider`, `AdminChurnProvider`, `AdminBypassProvider`, `AdminDisputesProvider`

---

## Next Priority Tasks

1. Wire `FilterChipPill` and `ShimmerList` into `search_screen.dart`
2. Apply `GlassCard` to `login_screen.dart`
3. Add `ChatEventContextHeader` to `chat_screen.dart`
4. Run Supabase migrations:
   - `20260823_add_country_to_users.sql`
   - `20260823_admin_phase8_phase9.sql`
5. Wire dispute list → `/admin/dispute-detail` from disputes screen
6. Add verification history tab in vendor management
7. Roll out l10n beyond vendor settings (242 ARB keys unused)
