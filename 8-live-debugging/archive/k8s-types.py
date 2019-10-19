def GenerateConfig(context):
  """Generate YAML resource configuration."""

  endpoints = {
      '-v1': 'api/v1',
      '-v1-apps': 'apis/apps/v1',
      '-v1beta1-extensions': 'apis/extensions/v1beta1',
      '-v1beta1-policy': 'apis/policy/v1beta1',
      '-v1-networking': 'apis/networking.k8s.io/v1'
  }

  resources = []
  outputs = []

  for type_suffix, endpoint in endpoints.iteritems():
    resources.append({
        'name': context.properties['cluster'] + type_suffix,
        'type': 'deploymentmanager.v2beta.typeProvider',
        'properties': {
            'options': {
                'validationOptions': {
                    'schemaValidation': 'IGNORE_WITH_WARNINGS'
                },
                'inputMappings': [{
                    'fieldName': 'name',
                    'location': 'PATH',
                    'methodMatch': '^(GET|DELETE|PUT)$',
                    'value': '$.ifNull('
                             '$.resource.properties.metadata.name, '
                             '$.resource.name)'
                }, {
                    'fieldName': 'metadata.name',
                    'location': 'BODY',
                    'methodMatch': '^(PUT|POST)$',
                    'value': '$.ifNull('
                             '$.resource.properties.metadata.name, '
                             '$.resource.name)'
                }, {
                    'fieldName': 'Authorization',
                    'location': 'HEADER',
                    'value': '$.concat("Bearer ",'
                             '$.googleOauth2AccessToken())'
                }]
            },
            'descriptorUrl':
                ''.join([
                    'https://' + context.properties['endpoint'] + '/swaggerapi/',
                    endpoint
                ])
        }
    })

  return {'resources': resources}

