import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UsageViewModel
    @State private var showingAddAccountSheet = false
    @State private var showingEditSheet = false
    @State private var accountToEdit: Account?
    @State private var newAccountName: String = ""
    @State private var newAccountKey: String = ""
    @State private var newAccountShowInMenuBar: Bool = true
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 450, minHeight: 400)
        .sheet(isPresented: $showingAddAccountSheet) {
            addAccountSheet
        }
        .sheet(item: $accountToEdit) { account in
            editAccountSheet(account)
        }
    }
    
    private var generalTab: some View {
        Form {
            Section("Accounts") {
                if viewModel.accounts.isEmpty {
                    emptyAccountsView
                } else {
                    ForEach(viewModel.accounts) { account in
                        accountRow(account)
                    }
                    .onDelete(perform: deleteAccounts)
                }
                
                Button(action: { showingAddAccountSheet = true }) {
                    Label("Add Account", systemImage: "plus.circle")
                }
                .buttonStyle(.link)
            }
            
            Section("Refresh Settings") {
                Toggle("Auto Refresh", isOn: $viewModel.autoRefreshEnabled)
                
                Picker("Refresh Interval", selection: $viewModel.refreshInterval) {
                    ForEach(UsageViewModel.RefreshInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .disabled(!viewModel.autoRefreshEnabled)
            }
            
            Section("Appearance") {
                Toggle("Show Dock Icon", isOn: $viewModel.showDockIcon)
                Text("When disabled, the app runs only in the menu bar. The dock icon will still be hidden when the settings window is open.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if showingSaveConfirmation {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Account saved successfully")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private var emptyAccountsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Accounts Added")
                .font(.headline)
            
            Text("Add your first Z.AI account to start monitoring usage.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    private func accountRow(_ account: Account) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.name)
                        .fontWeight(.medium)
                    
                    if viewModel.activeAccount?.id == account.id {
                        Text("Active")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    }
                }
                
                Text(account.obfuscatedKey)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                accountToEdit = account
            }) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Edit account")
        }
        .padding(.vertical, 4)
    }
    
    private var addAccountSheet: some View {
        VStack(spacing: 20) {
            Text("Add New Account")
                .font(.headline)
            
            Form {
                TextField("Account Name", text: $newAccountName)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("API Key", text: $newAccountKey)
                    .textFieldStyle(.roundedBorder)
                
                Toggle("Show in Menu Bar", isOn: $newAccountShowInMenuBar)

                Text("Get your API key from z.ai/manage-apikey/apikey-list")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismissAddSheet()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add") {
                    addAccount()
                }
                .disabled(newAccountName.isEmpty || newAccountKey.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .frame(width: 350, height: 420)
    }
    
    private func editAccountSheet(_ account: Account) -> some View {
        VStack(spacing: 20) {
            Text("Edit Account")
                .font(.headline)
            
            Form {
                TextField("Account Name", text: $newAccountName)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("API Key (leave empty to keep current)", text: $newAccountKey)
                    .textFieldStyle(.roundedBorder)
                    
                Toggle("Show in Menu Bar", isOn: $newAccountShowInMenuBar)
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismissEditSheet()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    saveEditedAccount(account)
                }
                .disabled(newAccountName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .frame(width: 350, height: 380)
        .onAppear {
            newAccountName = account.name
            newAccountKey = ""
            newAccountShowInMenuBar = account.showInMenuBar
        }
    }
    
    private var aboutTab: some View {
        VStack(spacing: 20) {
            Image(systemName: "gauge")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Z.AI Subscription Widget")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Version 1.0")
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Monitor your Z.AI Coding Plan usage")
                    .foregroundColor(.secondary)
                
                Link("Visit Z.AI", destination: URL(string: "https://z.ai")!)
                    .font(.callout)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            let account = viewModel.accounts[index]
            viewModel.removeAccount(account)
        }
    }
    
    private func addAccount() {
        viewModel.addAccount(name: newAccountName, apiKey: newAccountKey, showInMenuBar: newAccountShowInMenuBar)
        dismissAddSheet()
        showSaveConfirmation()
    }
    
    private func saveEditedAccount(_ account: Account) {
        var updated = account
        updated.name = newAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.showInMenuBar = newAccountShowInMenuBar
        
        // Only update API key if a new one was entered
        let trimmedKey = newAccountKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            updated.apiKey = trimmedKey
        }
        
        viewModel.updateAccount(updated)
        dismissEditSheet()
        showSaveConfirmation()
    }
    
    private func dismissAddSheet() {
        showingAddAccountSheet = false
        newAccountName = ""
        newAccountKey = ""
    }
    
    private func dismissEditSheet() {
        accountToEdit = nil
        newAccountName = ""
        newAccountKey = ""
    }
    
    private func showSaveConfirmation() {
        showingSaveConfirmation = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                showingSaveConfirmation = false
            }
        }
    }
}
