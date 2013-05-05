module Scrubber
  RSpec::Matchers.define(:present_groups_and_examples) do |*order|
    presented = order.map {|item| Presenter.for(item)}.join("\n")

    match do |text|
      text.chomp == presented
    end

    failure_message_for_should do |text|
      "expected order: \n#{presented}\n\n" +
        "but got: \n#{text}"
    end
  end
end
