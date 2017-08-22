defmodule Feeder.Telegram.Model do
  defmodule Response do
    defstruct message: nil,
              update_id: nil

    @type t :: %Response{
      message: Message.t
    }
  end

  defmodule Message do
    defstruct chat: nil,
              date: nil,
              from: nil,
              message_id: nil,
              text: nil

    @type t :: %Message{
      chat: Chat.t,
      date: integer,
      from: From.t,
      message_id: integer,
      text: String.t
    }
  end

  defmodule Chat do
    defstruct first_name: nil,
              id: nil,
              last_name: nil,
              type: nil,
              username: nil

    @type t :: %Chat{
      first_name: String.t,
      id: integer,
      last_name: String.t,
      type: String.t,
      username: String.t
    }
  end

  defmodule From do
    defstruct first_name: nil,
              id: nil,
              language_code: nil,
              last_name: nil,
              username: nil

    @type t :: %From{
      first_name: String.t,
      id: integer,
      language_code: String.t,
      last_name: String.t,
      username: String.t
    }
  end
end
