defmodule MyApp.Accounts do
  use Ash.Domain,
    otp_app: :my_app

  resources do
    resource MyApp.Accounts.Token
    resource MyApp.Accounts.User
  end
end
