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

  String get description {
    switch (this) {
      case LadderGameMode.penalty:
        return '누가 당첨될까? 공포의 벌칙!';
      case LadderGameMode.win:
        return '축하합니다! 행운의 주인공은?';
      case LadderGameMode.treat:
        return '오늘 점심은 누가 쏠까?';
      case LadderGameMode.order:
        return '정정당당하게 순서를 정해요';
      case LadderGameMode.manual:
        return '원하는 결과를 자유롭게 입력!';
      case LadderGameMode.team:
        return '공평하게 팀을 나눠보세요';
    }
  }
}
