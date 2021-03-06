require 'spec_helper'

describe ArticlesHelper do

  context 'link_to_tags helper method' do

    it 'generates a hyperlink to the filtered articles index page' do
      tag = 'hello'
      output = helper.link_to_tags [ tag ]
      output.should eq link_to(tag, articles_path(tag: tag))
    end

    it 'generates a comma separated link of tag links with multiple tags' do
      tags = %w( hello world )
      output = helper.link_to_tags tags
      output.should eq "#{link_to(tags[0], articles_path(tag: tags[0]))}, #{link_to(tags[1], articles_path(tag: tags[1]))}"
    end
  end

  context 'rendering markdown' do

    it 'should correctly render markdown tags' do
      markdown_text = "#heading\nthis is some *markdown* text `with code` and **bold** text"
      output = helper.from_markdown markdown_text

      output.should have_css 'h1'
      output.should have_css 'em'
      output.should have_css 'code'
      output.should have_css 'strong'
    end

    context 'preview' do
      it 'should render a truncated markdown text' do
        markdown_text = 'this is some `coding` done with **bold** text and some other random *stuff*' +
            'a lot of random text or rather that goes on and on and on and on and on and on and on' +
            "\n\n#heading\n until it reaches this heading"
        output = helper.markdown_preview markdown_text

        output.should have_css 'code'
        output.should have_css 'strong'
        output.should_not have_css 'h1'
        output.should_not have_css 'em'
      end

      it 'should not show links or image tags' do
        markdown_text = '`coding` can be really [fun](http://www.google.com) ![alt text](https://github.com/adam-p/markdown-here/raw/master/src/common/images/icon48.png "Logo Title Text 1")'
        output = helper.markdown_preview markdown_text

        output.should have_css 'code'
        output.should_not have_css 'a'
        output.should_not have_css 'img'
      end
    end
  end
end
