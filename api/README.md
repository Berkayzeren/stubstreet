# StubStreet API Contracts

This directory contains the API contract specifications for the StubStreet platform, including REST and GraphQL API definitions.

## Files Overview

### 1. `openapi.yaml`
Complete OpenAPI 3.0 specification for the StubStreet REST API, including:
- **Messaging endpoints**: User conversations and message handling
- **Purchase endpoints**: Ticket checkout and order confirmation
- **Authentication**: JWT and API key security schemes
- **Comprehensive schemas**: Detailed data models for all entities
- **Error handling**: Standardized error responses
- **Pagination**: Consistent pagination across endpoints

### 2. `graphql-schema.graphql`
GraphQL schema definition providing:
- **Queries**: Retrieve conversations and related data
- **Mutations**: Send messages, process payments, confirm orders
- **Type definitions**: Structured data types for all entities
- **Relationships**: Clear connections between data models

### 3. `versioning-plan.md`
Comprehensive versioning strategy document covering:
- **Semantic versioning** approach and lifecycle
- **Migration guidelines** for clients and developers
- **Deprecation process** and timeline
- **Best practices** for API evolution
- **Monitoring and analytics** for version adoption

## API Endpoints

### Messaging
- `GET /conversations` - Retrieve user conversations with pagination and filtering
- `POST /conversations/{id}/messages` - Send messages to specific conversations

### Purchase
- `POST /tickets/{id}/checkout` - Initiate ticket purchase and receive payment intent
- `POST /orders/confirm` - Confirm order after successful payment

## Key Features

### Security
- JWT Bearer token authentication
- API key authentication for service-to-service communication
- Rate limiting and request throttling

### Data Models
- **Conversation**: Multi-participant messaging containers
- **Message**: Individual messages with attachments support
- **Order**: Purchase records with ticket instances
- **PaymentIntent**: Secure payment processing integration
- **User**: Account information and authentication data

### Error Handling
- Consistent error response format
- HTTP status codes following REST conventions
- Detailed error messages with context
- Validation error details for bad requests

### Pagination
- Cursor-based pagination for large datasets
- Configurable page sizes with reasonable limits
- Metadata about total counts and navigation

## Usage Examples

### REST API
```bash
# Get conversations
curl -H "Authorization: Bearer <token>" \
     -H "Accept: application/vnd.stubstreet.v1+json" \
     https://api.stubstreet.com/v1/conversations

# Send message
curl -X POST \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{"content": "Hello, world!"}' \
     https://api.stubstreet.com/v1/conversations/{id}/messages

# Checkout ticket
curl -X POST \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{"paymentMethod": "card", "quantity": 2}' \
     https://api.stubstreet.com/v1/tickets/{id}/checkout
```

### GraphQL API
```graphql
# Query conversations
query GetConversations {
  conversations(page: 1, limit: 20) {
    id
    participants {
      id
      username
    }
    lastMessage {
      content
      createdAt
    }
  }
}

# Send message mutation
mutation SendMessage {
  sendMessage(conversationId: "123", content: "Hello!") {
    id
    content
    createdAt
  }
}

# Checkout ticket mutation
mutation CheckoutTicket {
  checkoutTicket(ticketId: "456", paymentMethod: "card") {
    id
    clientSecret
    amount
    currency
  }
}
```

## Development Workflow

### 1. API-First Development
- Design API contracts before implementation
- Use OpenAPI specification for code generation
- Validate requests/responses against schemas
- Generate client SDKs from specifications

### 2. Schema Validation
- Lint OpenAPI and GraphQL schemas
- Validate example requests/responses
- Check for breaking changes between versions
- Ensure backward compatibility

### 3. Documentation Generation
- Generate interactive API documentation
- Create code examples in multiple languages
- Provide migration guides for version changes
- Maintain changelog for all updates

### 4. Testing Strategy
- Contract testing with schema validation
- Integration testing across environments
- Performance testing for all endpoints
- Security testing for authentication/authorization

## Version Management

### Current Version: v1.0.0
- Initial release with core messaging and purchase functionality
- JWT authentication and basic pagination
- Standard error handling and response formats

### Planned Updates
- **v1.1.0**: Enhanced filtering, bulk operations, webhook support
- **v2.0.0**: OAuth 2.0 authentication, cursor-based pagination, improved data models

### Migration Support
- 6-month deprecation notice for breaking changes
- Backward compatibility shims where possible
- Comprehensive migration guides and tooling
- Developer support during transition periods

## Integration Guidelines

### Authentication
1. Obtain JWT token through authentication endpoint
2. Include `Authorization: Bearer <token>` header in all requests
3. Handle token expiration and refresh appropriately
4. Use API keys for server-to-server communication

### Error Handling
1. Check HTTP status codes for operation success/failure
2. Parse error response body for detailed error information
3. Implement retry logic for transient failures (429, 5xx)
4. Log errors with correlation IDs for debugging

### Rate Limiting
1. Respect rate limit headers in responses
2. Implement exponential backoff for rate limit violations
3. Monitor API usage to avoid hitting limits
4. Contact support for rate limit increases if needed

## Support and Resources

- **API Documentation**: https://docs.stubstreet.com/api
- **Developer Portal**: https://developers.stubstreet.com
- **Support Email**: api-support@stubstreet.com
- **Status Page**: https://status.stubstreet.com
- **GitHub Repository**: https://github.com/stubstreet/api-contracts

## Contributing

1. Fork the repository
2. Create feature branch for changes
3. Validate schemas and run tests
4. Submit pull request with detailed description
5. Ensure backward compatibility for existing clients
