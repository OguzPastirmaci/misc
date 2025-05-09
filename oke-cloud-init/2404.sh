## template: jinja
#cloud-config
{% if distro_release == 'noble' %}
apt:
    sources_list: |
      Types: deb
      URIs: https://odx-oke.objectstorage.us-sanjose-1.oci.customer-oci.com/n/odx-oke/b/okn-repositories/o/prod/ubuntu-noble/kubernetes-{{ ds.metadata['oke-k8version'].lstrip('v').split('.')[0] ~ '.' ~ ds.metadata['oke-k8version'].lstrip('v').split('.')[1] }}"
      Suites: $RELEASE
      Components: main
      Trusted: yes
{% elif distro_release == 'jammy' %}
apt:
 sources:
   oke-node: {source: 'deb [trusted=yes] https://odx-oke.objectstorage.us-sanjose-1.oci.customer-oci.com/n/odx-oke/b/okn-repositories/o/prod/ubuntu-noble/kubernetes-{{ ds.metadata['oke-k8version'].lstrip('v').split('.')[0] ~ '.' ~ ds.metadata['oke-k8version'].lstrip('v').split('.')[1] }}" stable main'}
packages:
 - oci-oke-node-all-{{ ds.metadata['oke-k8version'].lstrip('v') }}
runcmd:
 - oke bootstrap
{%- endif %}
