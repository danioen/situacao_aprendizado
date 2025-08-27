CREATE DATABASE loja;

CREATE TABLE clientes (
id int auto_increment primary key,
nome varchar(100) not null,
email varchar(100) not null,
cpf varchar(12) not null);


ALTER TABLE clientes DROP COLUMN cpf;

TRUNCATE table pedidos;
TRUNCATE table clientes;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE pedidos;
TRUNCATE TABLE clientes;
SET FOREIGN_KEY_CHECKS = 1;



CREATE TABLE pedidos(
id int auto_increment primary key,
cliente_id int not null,
descricao varchar(225) not null,
valor varchar(10) not null,

CONSTRAINT fk_pedidos_cliente
FOREIGN KEY (cliente_id) references clientes(id)
);
