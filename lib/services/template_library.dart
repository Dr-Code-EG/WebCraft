import '../models/element_node.dart';
import '../models/page_node.dart';
import '../models/project.dart';

/// A bundled starter project. Used as a seed when the user creates a new
/// project — copies the page tree and styles into the user's project so
/// they can edit freely.
class ProjectTemplate {
  ProjectTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.build,
  });

  final String id;
  final String name;
  final String icon; // material icon name shown in picker
  final List<PageNode> Function() build;
}

/// Curated catalog of starter templates.
class TemplateLibrary {
  TemplateLibrary._();

  static List<ProjectTemplate> all() => [
        ProjectTemplate(
          id: 'blank',
          name: 'Blank',
          icon: 'description',
          build: () => [
            PageNode(
              name: 'Home',
              fileName: 'index.html',
              title: 'Home',
              root: ElementNode.defaults(ElementType.container),
            ),
          ],
        ),
        ProjectTemplate(
          id: 'landing',
          name: 'Landing page',
          icon: 'rocket_launch',
          build: _buildLanding,
        ),
        ProjectTemplate(
          id: 'portfolio',
          name: 'Portfolio',
          icon: 'photo_library',
          build: _buildPortfolio,
        ),
        ProjectTemplate(
          id: 'blog',
          name: 'Blog post',
          icon: 'article',
          build: _buildBlog,
        ),
      ];

  /// Apply [template] to a brand-new project: replace its initial page list
  /// (the auto-created blank page) and reset selection.
  static void apply(Project project, ProjectTemplate template) {
    project.pages
      ..clear()
      ..addAll(template.build());
    project.activePageId = project.pages.first.id;
  }

  // --- Template builders ---------------------------------------------------

  static List<PageNode> _buildLanding() {
    final root = ElementNode(
      type: ElementType.container,
      style: {
        'padding': '0',
        'background': 'var(--bg, #ffffff)',
      },
      children: [
        ElementNode(
          type: ElementType.container,
          style: {
            'padding': '64px 32px',
            'background':
                'linear-gradient(135deg, var(--primary,#2563eb), var(--accent,#7c3aed))',
            'color': '#ffffff',
            'text-align': 'center',
          },
          children: [
            ElementNode(
              type: ElementType.heading,
              props: {'level': 'h1', 'text': 'Build the future, today'},
              style: {
                'font-size': '48px',
                'font-weight': '800',
                'margin-bottom': '16px',
                'color': '#ffffff',
              },
            ),
            ElementNode(
              type: ElementType.paragraph,
              props: {
                'text':
                    'Beautiful websites without writing a single line of code.'
              },
              style: {
                'font-size': '18px',
                'opacity': '0.9',
                'margin-bottom': '24px',
              },
            ),
            ElementNode(
              type: ElementType.button,
              props: {'text': 'Get started', 'type': 'button'},
              style: {
                'background': '#ffffff',
                'color': 'var(--primary,#2563eb)',
                'padding': '12px 28px',
                'border-radius': '999px',
                'font-weight': '600',
                'border': 'none',
                'cursor': 'pointer',
              },
            ),
          ],
        ),
        ElementNode(
          type: ElementType.container,
          style: {
            'padding': '64px 32px',
            'max-width': '1100px',
            'margin': '0 auto',
          },
          children: [
            ElementNode(
              type: ElementType.heading,
              props: {'level': 'h2', 'text': 'Why WebCraft?'},
              style: {
                'font-size': '32px',
                'text-align': 'center',
                'margin-bottom': '32px',
              },
            ),
            ElementNode(
              type: ElementType.row,
              style: {'gap': '24px', 'flex-direction': 'row'},
              children: [
                _featureCard('Drag & drop',
                    'Visual editor that feels like Sketchware.'),
                _featureCard('Real code',
                    'Export clean HTML, CSS and JS to any host.'),
                _featureCard('Block logic',
                    'Snap-together blocks generate JavaScript.'),
              ],
            ),
          ],
        ),
      ],
    );
    return [
      PageNode(
        name: 'Home',
        fileName: 'index.html',
        title: 'Landing — WebCraft',
        root: root,
      ),
    ];
  }

  static ElementNode _featureCard(String title, String body) {
    return ElementNode(
      type: ElementType.card,
      style: {
        'padding': '24px',
        'background': 'var(--surface,#f9fafb)',
        'border-radius': 'var(--radius,8px)',
        'border': '1px solid var(--border,#e5e7eb)',
        'flex': '1',
      },
      children: [
        ElementNode(
          type: ElementType.heading,
          props: {'level': 'h3', 'text': title},
          style: {'font-size': '18px', 'margin-bottom': '8px'},
        ),
        ElementNode(
          type: ElementType.paragraph,
          props: {'text': body},
          style: {'color': 'var(--muted,#6b7280)'},
        ),
      ],
    );
  }

  static List<PageNode> _buildPortfolio() {
    final root = ElementNode(
      type: ElementType.container,
      style: {
        'max-width': '900px',
        'margin': '0 auto',
        'padding': '48px 24px',
      },
      children: [
        ElementNode(
          type: ElementType.heading,
          props: {'level': 'h1', 'text': 'Hi, I\u2019m Alex.'},
          style: {'font-size': '40px', 'margin-bottom': '8px'},
        ),
        ElementNode(
          type: ElementType.paragraph,
          props: {
            'text':
                'I\u2019m a designer & developer who loves shipping delightful products.'
          },
          style: {
            'color': 'var(--muted,#6b7280)',
            'font-size': '18px',
            'margin-bottom': '32px',
          },
        ),
        ElementNode(
          type: ElementType.heading,
          props: {'level': 'h2', 'text': 'Selected work'},
          style: {'font-size': '24px', 'margin-bottom': '16px'},
        ),
        ElementNode(
          type: ElementType.row,
          style: {'gap': '16px'},
          children: [
            _portfolioItem('Project Alpha', 'Mobile app · 2024'),
            _portfolioItem('Project Beta', 'Web app · 2023'),
            _portfolioItem('Project Gamma', 'Brand · 2023'),
          ],
        ),
      ],
    );
    return [
      PageNode(
        name: 'Home',
        fileName: 'index.html',
        title: 'Portfolio',
        root: root,
      ),
    ];
  }

  static ElementNode _portfolioItem(String title, String subtitle) {
    return ElementNode(
      type: ElementType.card,
      style: {
        'padding': '20px',
        'background': 'var(--surface,#f9fafb)',
        'border-radius': 'var(--radius,8px)',
        'flex': '1',
      },
      children: [
        ElementNode(
          type: ElementType.heading,
          props: {'level': 'h3', 'text': title},
          style: {'font-size': '16px', 'margin-bottom': '4px'},
        ),
        ElementNode(
          type: ElementType.paragraph,
          props: {'text': subtitle},
          style: {'color': 'var(--muted,#6b7280)', 'font-size': '13px'},
        ),
      ],
    );
  }

  static List<PageNode> _buildBlog() {
    final root = ElementNode(
      type: ElementType.container,
      style: {
        'max-width': '720px',
        'margin': '0 auto',
        'padding': '48px 24px',
      },
      children: [
        ElementNode(
          type: ElementType.heading,
          props: {'level': 'h1', 'text': 'My first blog post'},
          style: {'font-size': '36px', 'margin-bottom': '8px'},
        ),
        ElementNode(
          type: ElementType.paragraph,
          props: {'text': 'Posted on January 1, 2025 · 4 min read'},
          style: {
            'color': 'var(--muted,#6b7280)',
            'font-size': '13px',
            'margin-bottom': '24px',
          },
        ),
        ElementNode(
          type: ElementType.paragraph,
          props: {
            'text':
                'Welcome to my new blog. I\u2019ll be writing about the things I\u2019m building and the lessons I learn along the way.'
          },
          style: {
            'font-size': '17px',
            'line-height': '1.7',
            'margin-bottom': '20px',
          },
        ),
        ElementNode(
          type: ElementType.heading,
          props: {'level': 'h2', 'text': 'Why I\u2019m writing this'},
          style: {'font-size': '22px', 'margin-bottom': '12px'},
        ),
        ElementNode(
          type: ElementType.paragraph,
          props: {
            'text':
                'I\u2019ve always learned best by writing things down. This blog is my notebook in public.'
          },
          style: {
            'font-size': '17px',
            'line-height': '1.7',
            'margin-bottom': '20px',
          },
        ),
      ],
    );
    return [
      PageNode(
        name: 'Home',
        fileName: 'index.html',
        title: 'My first blog post',
        root: root,
      ),
    ];
  }
}
