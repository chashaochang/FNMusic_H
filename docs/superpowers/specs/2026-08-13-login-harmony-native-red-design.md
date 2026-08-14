# Login HarmonyOS Native Red Design Specification

**Status:** Approved for implementation

**Date:** 2026-08-13

## 1. Goal

Replace the current Android/Material-like login form with a phone-first HarmonyOS API 26 native experience. The screen must retain the existing FN Connect authentication behavior while using system semantic colors, immersive material, restrained Feiniu Music red, responsive keyboard handling, and continuous state transitions.

## 2. Scope

This change covers only the unauthenticated login surface and the small native-theme infrastructure it requires. It does not change the FNID resolution or NAS authentication protocol, does not add alternative login methods, and does not broadly recolor authenticated application pages.

## 3. Visual Direction

- The page follows the system color mode and uses HarmonyOS semantic canvas, text, icon, divider, and interactive colors.
- Feiniu Music red is the brand/action color. It is reserved for the brand mark, focus indication, primary action, progress, links, and non-error emphasis.
- Error red remains a separate semantic color and must never reuse the brand token.
- The form is unframed. There is no large opaque card surrounding all fields.
- Input fields are transparent controls clipped over API 26 `uiMaterial.ImmersiveMaterial` adaptive interactive surfaces.
- The primary button is a 48vp capsule using an interactive red material, a white light effect, and a restrained shadow.
- Decorative light is expressed by native material response and one subtle brand atmosphere layer, not gradients or free-floating decorative blobs.
- Typography stays within the verified phone baseline: 20fp title, 15fp field/action text, 13fp supporting text, and 12fp privacy copy.

## 4. Layout

- The root fills the window and expands through the top and bottom system safe areas. The scroll content itself owns the readable insets.
- Horizontal page padding is 20vp. The form is constrained to a maximum width of 420vp and centered on wider phone windows.
- The header begins after the top safe area and contains a 48vp red material brand mark, a 20fp title, and one supporting line.
- Header-to-form spacing is 28vp. Fields use 12vp vertical spacing.
- Each input field is 52vp high with a 14vp radius. Internal horizontal padding is 16vp; fields with a trailing action reserve 48vp on the right.
- The primary button is 48vp high with a 24vp radius.
- The security-code disclosure is a compact 40vp row and expands directly into the optional field.
- Privacy copy remains below the form and is centered without manual line breaks.

## 5. Components

Dynamic data must be rendered by `@ComponentV2` child components, not dynamic `@Builder` functions.

- `LoginBrandHeader`: native brand mark, title, and subtitle.
- `NativeLoginField`: text/password field with material, focus outline, optional password visibility action, submit event, and accessibility label.
- `SecurityCodeSection`: disclosure control and animated optional field.
- `LoginStatusMessage`: error or informational status with semantic icon/color.
- `LoginPrimaryAction`: enabled, disabled, and loading states on the native red material.
- `LoginRetryAction`: secondary material action shown only when retry is allowed.

## 6. State Matrix

| State | Fields | Primary action | Status/transition |
| --- | --- | --- | --- |
| Empty | Placeholder and no focus ring | Disabled, low-emphasis material | No message unless runtime supplies one |
| Partially entered | Entered text retained | Disabled until FNID, username, and password are all non-empty | No layout jump |
| Focused | 2vp brand-red outline and visible caret | Form remains interactive | Focus change animates over 160ms |
| Ready | All required values present | Enabled red interactive material | Submit from password keyboard or button |
| Loading | Values remain visible, fields and disclosure disabled | Spinner plus phase-specific label | Content does not resize horizontally |
| Error | Values remain editable | Enabled when required fields remain present | Error panel uses semantic danger color, not brand red |
| Retry available | Normal form remains visible | Normal sign-in plus secondary retry action | Retry action uses adaptive material |
| Security code collapsed | Disclosure says `填写安全码` | No optional field | Chevron points down |
| Security code expanded | Optional password field visible | Required-field rule unchanged | Field enters with opacity and downward translation |
| Light mode | Light system canvas and dark semantic text | Saturated Feiniu red | Material remains translucent |
| Dark mode | Dark system canvas and light semantic text | Red adjusted for dark contrast | Error and disabled colors remain distinct |
| Keyboard shown | Scroll view permits focused field and action to remain reachable | No duplicated safe-area allocation | Content can scroll with spring edge effect |

## 7. Interaction And Motion

- Password visibility uses the system eye/eye-slash symbol and an explicit accessibility label.
- Security-code expansion uses an asymmetric opacity and translate transition of approximately 180ms.
- Status message insertion/removal uses opacity plus a small vertical translation of approximately 180ms.
- Focus outlines and disclosure chevron changes animate over 160ms using `Curve.FastOutSlowIn`.
- The login button never swaps to a differently sized loading block. It keeps a stable 48vp frame and replaces its inner content.
- Busy state blocks duplicate submission and disables all editable controls.

## 8. Color Tokens

Both `base` and `dark` resource sets must define:

- `login_canvas`: native page canvas.
- `brand_red`: Feiniu Music brand/action red.
- `brand_red_soft`: restrained brand atmosphere tint.
- `brand_on_red`: foreground on the red primary action.
- `login_material_tint`: neutral input/retry material tint.
- `login_disabled_fill` and `login_disabled_text`: disabled primary action.
- `focus_outline`: focus indication mapped to brand red.

Existing `danger` and `danger_soft` remain the only error colors.

## 9. Accessibility And Reliability

- Every icon-only button has an accessibility label.
- Tappable actions have at least a 40vp interaction frame; primary action is 48vp.
- Text uses natural wrapping and does not include forced newline characters.
- Required-field readiness is computed from trimmed FNID and username plus a non-empty password.
- The implementation must compile against target and compatible SDK 26.0.0 and must not introduce new package dependencies.

## 10. Acceptance

- All states in the matrix are represented in source and compile successfully.
- Base and dark colors are both present.
- No dynamic login content is implemented through `@Builder`.
- LocalUnit tests continue to pass.
- The UI size guard is reviewed with no unjustified new large values.
- The API 26 HAP builds and passes archive integrity validation.
- Device visual acceptance is reported separately and only claimed after install, launch, and screenshot inspection on an online device.
