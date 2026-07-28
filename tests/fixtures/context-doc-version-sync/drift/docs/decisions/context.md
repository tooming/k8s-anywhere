# Lab context & live decisions (fixture)

- Dashboards sync from GitLab via Grafana native Git Sync; Grafana 13.0.1 on
  `kubernetesDashboards`/unified storage.
- **Profiles**: **Pyroscope** (chart 2.2.0, single-binary, Garage-backed bucket).
- **KRO** (0.9.2, ns `kro`) adds a ResourceGraphDefinition `S3BucketClaim`.
