# Implement SSL/TLS at ALB Level with ACM Certificate

## Issue Description
Move SSL/TLS termination from nginx to the Application Load Balancer (ALB) using AWS Certificate Manager (ACM) for proper HTTPS support with the custom domain `wwiz.firman.id.au`.

## Current State
- ✅ **DNS Setup**: Route 53 configured with `wwiz.firman.id.au` pointing to ALB
- ✅ **HTTP Working**: Application accessible via HTTP through ALB
- ❌ **HTTPS Missing**: No SSL/TLS termination configured
- ❌ **Certificate Missing**: No ACM certificate for the domain

## Proposed Solution

### **Phase 1: Certificate Management (CloudFormation Changes)**

#### 1. Request ACM Certificate
- Add ACM certificate resource to CloudFormation template
- Request certificate for `wwiz.firman.id.au`
- Include DNS validation method
- **Question**: Will this trigger EC2 instance rebuild? 🤔

#### 2. Configure ALB HTTPS Listener  
- Add HTTPS listener (port 443) to ALB
- Attach ACM certificate to HTTPS listener
- **Question**: Will this trigger EC2 instance rebuild? 🤔

#### 3. Set up HTTP → HTTPS Redirection
- Configure HTTP listener (port 80) to redirect to HTTPS
- Add redirect rule to force HTTPS traffic
- **Question**: Will this trigger EC2 instance rebuild? 🤔

### **Phase 2: Nginx Configuration (Script Changes)**

#### 4. Update Nginx Configuration
- Remove SSL/TLS configuration from nginx
- Configure nginx for HTTP-only backend service
- Update proxy settings for ALB → nginx communication
- **Question**: Can we just update `nginx.conf` and re-run `setup-ai-poc.sh`? 🤔

## Technical Analysis Required

### **CloudFormation Impact Assessment**
Need to confirm if adding these resources will trigger EC2 instance replacement:
- ACM Certificate resource
- ALB HTTPS Listener modification  
- ALB HTTP Listener redirect rule

**Expected**: Should NOT trigger instance rebuild (ALB-level changes only)
**Verification needed**: Review CloudFormation change set before deployment

### **Nginx Configuration Changes**
Current `nginx.conf` needs modification:
```nginx
# Remove SSL configuration blocks
# Update server block to listen only on port 80
# Ensure proxy headers are appropriate for ALB termination
```

**Expected**: Simple configuration file change + script re-run
**Verification needed**: Confirm if `setup-ai-poc.sh` re-run handles nginx config updates

## Implementation Steps

### **Step 1: CloudFormation Template Updates**
```yaml
# Add ACM Certificate
Certificate:
  Type: AWS::CertificateManager::Certificate
  Properties:
    DomainName: wwiz.firman.id.au
    ValidationMethod: DNS

# Add HTTPS Listener
ListenerHTTPS:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    LoadBalancerArn: !Ref ALB
    Port: 443
    Protocol: HTTPS
    Certificates:
      - CertificateArn: !Ref Certificate

# Modify HTTP Listener for redirect
ListenerHTTP:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    DefaultActions:
      - Type: redirect
        RedirectConfig:
          Protocol: HTTPS
          Port: 443
          StatusCode: HTTP_301
```

### **Step 2: Nginx Configuration Update**
```nginx
server {
    listen 80;
    server_name _;
    
    # Remove SSL configuration
    # Keep health check endpoint
    # Update proxy headers for ALB
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### **Step 3: Deployment Process**
1. Update CloudFormation template
2. Deploy via `update-stack.ps1`
3. Validate certificate creation and DNS validation
4. Update `nginx.conf` in repository
5. Re-run `setup-ai-poc.sh` on EC2 instance
6. Test HTTPS access via `https://wwiz.firman.id.au`

## Cleanup Required

### **Issue #10 Cleanup**
If this solution works, need to clean up previous SSL implementation:
- Remove nginx SSL configuration files
- Remove self-signed certificate generation
- Remove SSL-related scripts and setup
- Update documentation to reflect ALB SSL termination

## Questions for Validation

1. **CloudFormation Impact**: Will adding ACM certificate and ALB listener changes trigger EC2 instance rebuild?
2. **Nginx Update**: Can we simply update `nginx.conf` and re-run `setup-ai-poc.sh` for the configuration changes?
3. **Certificate Validation**: Will DNS validation work automatically with Route 53, or do we need manual intervention?
4. **Rollback Plan**: What's the rollback procedure if ALB SSL doesn't work as expected?

## Success Criteria

✅ **HTTPS Access**: `https://wwiz.firman.id.au` returns AnythingLLM interface  
✅ **HTTP Redirect**: `http://wwiz.firman.id.au` automatically redirects to HTTPS  
✅ **Certificate Valid**: Browser shows valid SSL certificate (not self-signed)  
✅ **No Downtime**: Deployment doesn't require EC2 instance rebuild  
✅ **Clean Configuration**: Nginx serves as simple HTTP backend proxy  

## Priority
**High** - Required for professional domain access with proper SSL

## Labels
- `enhancement`
- `ssl-tls`
- `alb`
- `acm`
- `domain`
- `cloudformation`
- `infrastructure`

## Dependencies
- Route 53 DNS already configured ✅
- Domain ownership verified ✅
- ALB currently working with HTTP ✅
