# Payment gateway logos

Drop the official logo files here, named as the registry
(`lib/features/builder/domain/payment_gateways.dart`) expects. Either `.svg`
or `.png` works — the wizard picks the renderer from the extension. An
optional `*-dark.(svg|png)` variant is shown instead on a dark tile.

| Gateway | Logo | Optional dark-background variant |
|---------|------|-----------------------------------|
| HyperPay | `hyperpay.png` | `hyperpay-dark.(svg\|png)` |
| Paymob | `paymob.png` | `paymob-dark.(svg\|png)` |
| Amazon Payment Services (PayFort) | `aps.png` | `aps-dark.(svg\|png)` |

Use the files exactly as the brand provides them: the wizard shows them
uncropped, unstretched and not recolored, on a white tile (Paymob's own file
is a solid-blue badge, so its tile reads as a blue square — that's the file,
not a bug). Until a file is here (or if it fails to load) the tile shows the
gateway's initials instead.
