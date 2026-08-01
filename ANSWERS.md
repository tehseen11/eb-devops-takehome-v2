
## Q1. Migrating from ingress-nginx to Kubernetes Gateway API with no downtime

I would approach the migration gradually to avoid impacting existing traffic.

First, I would inventory all existing Ingress objects, hosts, paths, TLS configurations, annotations, and controller-specific features being used. I would identify any ingress-nginx-specific behaviours that need equivalent Gateway API implementations.

Next, I would install the Gateway API CRDs and deploy a Gateway API compatible controller alongside the existing ingress-nginx controller. I would configure the new GatewayClass, Gateway, and HTTPRoute resources without removing the existing Ingress objects.

I would migrate applications incrementally. For each service, I would create equivalent HTTPRoute resources and validate routing, TLS termination, headers, redirects, authentication, and other behaviours in a staging environment first.

For production migration, I would use a controlled traffic migration strategy. This could involve DNS changes with low TTL values, weighted routing if supported by the Gateway controller, or running both configurations temporarily and switching traffic gradually.

During migration, I would monitor error rates, latency, availability, and application logs. Common issues I would expect include unsupported ingress annotations, path matching differences, TLS configuration problems, missing permissions, and controller-specific behaviour changes.

After all traffic is successfully migrated and stable, I would remove old Ingress resources and decommission ingress-nginx.

The main risks are hidden dependencies on ingress-nginx annotations and unexpected routing differences, so observability and rollback capability are essential throughout the migration.
