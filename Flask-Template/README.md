# FOR US TO DO BEFORE SHIPPING

- [ ] Security Considerations
      Flask Talisman: It's excellent to see Flask-Talisman in use. Make sure to define a reasonable content*security_policy instead of setting it to None, as CSP is a critical security header for protecting against XSS attacks.
      CORS Policy: Be cautious with CORS(app, resources={r"/api/*": {"origins": "\_"}}). Defining a wildcard origin (\*) can expose your API to cross-site attacks. Specify the exact origins you need.

- [ ] GitHub Actions for CI/CD
      CI Improvements: Consider breaking down the CI steps into more granular actions for better maintainability and clarity.
      Deployment Considerations: Deployment steps should ensure rollback capabilities and zero-downtime deployments if applicable.

---

### TODO:

- [ ] Create MongoDB Atlas Account
- [ ] Create MongoDB Project
- [ ] Create MongoDB Cluster in the Project
- [ ] Create at least two databases in your Cluster
- [ ] Create 4 database Users and log their passwords somewhere safe

  - [ ] Create a single User for each database to only have read permissions to their assigned DB
  - [ ] Create a single User for each database to only have readWrite permissions to their assigned DB
  - [ ] Create connection strings for each database User and put them in the .flaskenv with names corresponding to what you name the database connections in config.py and app/database/connections.py
