<!DOCTYPE html>

{# NexT version #}
{%- set version = next_env('version') %}

{# Language & Config #}
{%- set title = __('title') !== 'title' and __('title') or config.title %}
{%- set subtitle = __('subtitle') !== 'subtitle' and __('subtitle') or config.subtitle %}
{%- set author = __('author') !== 'author' and __('author') or config.author %}
{%- set description = __('description') !== 'description' and __('description') or config.description %}

{%- if theme.pjax %}
  {%- set pjax = ' pjax' %}
{%- endif %}

<html lang="{{ config.language }}">
<head>
  {{ partial('_partials/head/head.swig', {}, {cache: theme.cache.enable}) }}
  {% include '_partials/head/head-unique.swig' %}
  {{- next_inject('head') }}
  <title>{% block title %}{% endblock %}</title>
  {{ partial('_third-party/analytics/index.swig', {}, {cache: theme.cache.enable}) }}
  {{ partial('_scripts/noscript.swig', {}, {cache: theme.cache.enable}) }}
</head>

<body itemscope itemtype="http://schema.org/WebPage" lang="{{ page.lang or page.language or config.language }}">
  <div class="container{%- if theme.motion.enable %} use-motion{%- endif %}">
    <div class="headband"></div>

    <header id="header" class="header" itemscope itemtype="http://schema.org/WPHeader">
      <div class="header-inner">{% include '_partials/header/index.swig' %}</div>
    </header>

    {{ partial('_partials/widgets.swig', {}, {cache: theme.cache.enable}) }}

    <main id="main" class="main">
      <div class="main-inner">
        <div class="content-wrap">
          {%- if theme.scheme === 'Pisces' or theme.scheme === 'Gemini' %}
            {% include '_partials/header/sub-menu.swig' %}
          {%- endif %}
          <div id="content" class="content">
            {% block content %}{% endblock %}
          </div>
          {% include '_partials/comments.swig' %}
        </div>
        {%- if theme.sidebar.display !== 'remove' %}
          {% block sidebar %}{% endblock %}
        {%- endif %}
      </div>
    </main>

    <footer id="footer" class="footer">
      <div class="footer-inner">
        {{ partial('_partials/footer.swig', {}, {cache: theme.cache.enable}) }}
        {{ partial('_partials/analytics/index.swig', {}, {cache: theme.cache.enable}) }}
        {% block footer %}{% endblock %}
      </div>
    </footer>
  </div>

  {{ partial('_scripts/index.swig', {}, {cache: theme.cache.enable}) }}
  {{ partial('_third-party/index.swig', {}, {cache: theme.cache.enable}) }}

  {%- if theme.pjax %}
    <div id="pjax">
  {%- endif %}

  {% include '_third-party/math/index.swig' %}
  {% include '_third-party/quicklink.swig' %}
  {% include '_third-party/vkontakte-api.swig' %}

  {{- next_inject('bodyEnd') }}

  {%- if theme.pjax %}
    </div>
  {%- endif %}

  <script>
    [].slice.call(document.querySelectorAll('.header-inner .site-lang span')).map(el=>{
      el.addEventListener('click',function(){
        if( this.dataset.lang === 'cn'){
          window.location.href = 'https://carljin.com'  + window.location.pathname
        }else{
          window.location.href = 'https://en.carljin.com'  + window.location.pathname
        }
      })
    })
  </script>
  <script>
    function set_image_size(image, width, height)
    {
      image.setAttribute("width", width + "px");
      image.setAttribute("height", height + "px");
    }

    function hexo_resize_image()
    {
      var imgs = document.getElementsByTagName('img');
      for (var i = imgs.length - 1; i >= 0; i--)
      {
        var img = imgs[i];

        var src = img.getAttribute('src').toString();

        var fields = src.match(/(?<=\?)\d*x\d*/g);
        if (fields && fields.length == 1)
        {
          var values = fields[0].split("x");
          if (values.length == 2)
          {
            var width = values[0];
            var height = values[1];

            if (!(width.length && height.length))
            {
              var n_width = img.naturalWidth;
              var n_height = img.naturalHeight;
              if (width.length > 0)
              {
                height = n_height*width/n_width;
              }
              if (height.length > 0)
              {
                width = n_width*height/n_height;
              }
            }
            set_image_size(img, width, height);
          }
          continue;
        }

        fields = src.match(/(?<=\?)\d*/g);
        if (fields && fields.length == 1)
        {
          var scale = parseFloat(fields[0].toString());
          var width = scale/100.0*img.naturalWidth;
          var height = scale/100.0*img.naturalHeight;
          set_image_size(img, width, height);
        }
      }
    }
    window.onload = hexo_resize_image;
  </script>
</body>
</html>
