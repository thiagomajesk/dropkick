# Dropkick

Dropkick is a highly experimental library that provides easy to use uploads for the Elixir/ Phoenix ecosystem.
This is a opinionated library focused on developer ergonomics that you can use to provide file uploads in any Phoenix project.

Some inspiration was taken from other projects like [Capsule](https://github.com/elixir-capsule/capsule) and [Waffle](https://github.com/elixir-waffle/waffle) as well as Ruby's [Shrine](https://shrinerb.com/). 

## Installation

```elixir
def deps do
  [
    {:dropkick, "~> 0.1.0"}
  ]
end
```

## Missing bits

- Increase test coverage
- Implement more image transformations
- Add video transformations
- Add support to S3 storage