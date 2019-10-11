{{ partial('_partials/header/brand.swig', {}, {cache: theme.cache.enable}) }}

{%- set hasSearch = theme.algolia_search.enable or theme.local_search.enable %}

<nav class="site-nav">
  {{ partial('_partials/header/menu.swig', {}, {cache: theme.cache.enable}) }}

  {%- if theme.scheme === 'Muse' or theme.scheme === 'Mist' %}
    {% include 'sub-menu.swig' %}
  {%- endif %}
</nav>

{%- if hasSearch %}
  <div class="site-search">
    {{ partial('_partials/search/index.swig', {}, {cache: theme.cache.enable}) }}
  </div>
{%- endif %}

<div class="site-lang">
  <span class="active" data-lang="cn">中文</span><span data-lang="en">English</span>
</div>

{{- next_inject('header') }}
