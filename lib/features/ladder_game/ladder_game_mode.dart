enum LadderGameMode {
  penalty('벌칙', '💀'),
  win('당첨', '🎁'),
  treat('쏘기', '☕'),
  order('순서', '🔢'),
  team('팀 나누기', '🤝'),
  manual('직접 입력', '✍️');

  final String label;
  final String icon;

  const LadderGameMode(this.label, this.icon);
}
