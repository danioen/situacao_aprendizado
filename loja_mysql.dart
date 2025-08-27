import 'package:mysql_client/mysql_client.dart';


class Cliente {
  int? id;
  String nome;
  String email;

  Cliente({this.id, required this.nome, required this.email});

  @override
  String toString() => 'Cliente(id: $id, nome: $nome, email: $email)';
}

class Pedido {
  int? id;
  int clienteId;
  String descricao;
  double valor;

  Pedido({
    this.id,
    required this.clienteId,
    required this.descricao,
    required this.valor,
  });

  @override
  String toString() =>
      'Pedido(id: $id, clienteId: $clienteId, desc: $descricao, valor: $valor)';
}

///acesso ao mysql

class Banco {
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  late final MySQLConnection _conn;

  Banco({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  Future<void> conectar() async {
    _conn = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: user,
      password: password,
      databaseName: database,
      secure: false,
    );
    await _conn.connect();
    print('----Conectado ao MySQL ($database)----');
  }

  Future<void> fechar() async {
    await _conn.close();
  }

  /// INSERT cliente e retorna o id gerado
  Future<int> inserirCliente(Cliente c) async {
    // validação simples
    if (c.nome.trim().isEmpty || c.email.trim().isEmpty) {
      throw ArgumentError('Nome e e-mail são obrigatórios');
    }

    await _conn.execute(
      'INSERT INTO clientes (nome, email) VALUES (:nome, :email)',
      {'nome': c.nome, 'email': c.email},
    );

    final rs = await _conn.execute('SELECT LAST_INSERT_ID() AS id');
    final idStr = rs.rows.first.colByName('id')!;
    c.id = int.parse(idStr);
    return c.id!;
  }

  /// INSERT pedido e retorna o id gerado
  Future<int> inserirPedido(Pedido p) async {
    if (p.valor < 0) throw ArgumentError('Valor do pedido não pode ser negativo');

    await _conn.execute(
      'INSERT INTO pedidos (cliente_id, descricao, valor) '
      'VALUES (:cliente_id, :descricao, :valor)',
      {
        'cliente_id': p.clienteId,
        'descricao': p.descricao,
        'valor': p.valor.toStringAsFixed(2),
      },
    );

    final rs = await _conn.execute('SELECT LAST_INSERT_ID() AS id');
    final idStr = rs.rows.first.colByName('id')!;
    p.id = int.parse(idStr);
    return p.id!;
  }

  /// SELECT com JOIN: lista pedidos com dados do cliente
  Future<void> listarPedidosComCliente() async {
    print('--Pedidos (com dados do cliente):--');
    final rs = await _conn.execute('''
      SELECT p.id AS pedido_id,
             c.nome AS cliente,
             p.descricao,
             p.valor
      FROM pedidos p
      JOIN clientes c ON c.id = p.cliente_id
      ORDER BY p.id;
    ''');

    for (final row in rs.rows) {
      final pedidoId = row.colByName('pedido_id');
      final cliente = row.colByName('cliente');
      final desc = row.colByName('descricao');
      final valor = row.colByName('valor');
    print(' - #$pedidoId | $cliente | "$desc" | R\$ $valor |');
    }
  }

  /// SELECT com GROUP BY: total gasto por cliente
  Future<void> resumoPorCliente() async {
    print('---Resumo por cliente:---');
    final rs = await _conn.execute('''
      SELECT c.nome AS cliente,
             SUM(p.valor) AS total_gasto,
             COUNT(p.id) AS qtd_pedidos
      FROM clientes c
      LEFT JOIN pedidos p ON p.cliente_id = c.id
      GROUP BY c.id, c.nome
      ORDER BY total_gasto DESC;
    ''');

    for (final row in rs.rows) {
      final cliente = row.colByName('cliente');
      final total = row.colByName('total_gasto') ?? '0.00';
      final qtd   = row.colByName('qtd_pedidos') ?? '0';
      print(' - $cliente | pedidos: $qtd | total: R\$ $total');
    }
  }
}


/// inserindo pedidos e imprimindo os relatórios pedidos no enunciado.
Future<void> main() async {
  
  final db = Banco(
    host: '127.0.0.1',
    port: 3306,
    user: 'daniela',         
    password: 'senha',
    database: 'loja',
  );

  await db.conectar();


  try {
    // 1) Inserir clientes
    final cliente1 = Cliente(nome: 'Ana Silva',  email: 'ana@gmail.com');
    final cliente2 = Cliente(nome: 'Bruno Melo', email: 'bruno@gmail.com');

    final c1 = await db.inserirCliente(cliente1);
    final c2 = await db.inserirCliente(cliente2);
    print('Clientes inseridos: $c1, $c2');

    // 2) Inserir pedidos
    await db.inserirPedido(
      Pedido(clienteId: c1, descricao: 'Teclado Mecânico', valor: 320.00),
    );
    await db.inserirPedido(
      Pedido(clienteId: c1, descricao: 'Headset USB', valor: 180.50),
    );
    await db.inserirPedido(
      Pedido(clienteId: c2, descricao: 'Mouse Gamer', valor: 149.90),
    );

    // 3) SELECT com JOIN
    await db.listarPedidosComCliente();

    // 4) SELECT com GROUP BY
    await db.resumoPorCliente();
  } finally {
    await db.fechar();
  }
}
