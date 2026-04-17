import AppIntents

// AppShortcutsProvider le dice a iOS qué acciones exponer en la app Atajos.
// iOS las muestra automáticamente bajo el nombre "fina." con el ícono de la app.
struct FinaShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {

        AppShortcut(
            intent: ApplePayAutomationIntent(),
            phrases: [
                "Registrar pago de Apple Pay en \(.applicationName)",
                "Automatizar Apple Pay con \(.applicationName)",
            ],
            shortTitle: "Automatización de Apple Pay",
            systemImageName: "creditcard"
        )

        AppShortcut(
            intent: NewTransactionIntent(),
            phrases: [
                "Nueva transacción en \(.applicationName)",
                "Registrar gasto en \(.applicationName)",
            ],
            shortTitle: "Nueva transacción",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: TransactionFromMessageIntent(),
            phrases: [
                "Registrar transacción desde mensaje en \(.applicationName)",
            ],
            shortTitle: "Transacción desde mensaje",
            systemImageName: "message"
        )

        AppShortcut(
            intent: BankSMSIntent(),
            phrases: [
                "Registrar SMS bancario en \(.applicationName)",
                "Guardar transacción bancaria en \(.applicationName)",
            ],
            shortTitle: "SMS Bancario",
            systemImageName: "building.columns"
        )
    }
}
