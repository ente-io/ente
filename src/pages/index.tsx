import React from 'react';
import styled, { css } from 'styled-components';
import Card from 'react-bootstrap/Card';
import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';

const Container = styled.div`
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
`;

export default function Home() {
  return (
      <Container>
        <Card style={{ minWidth: '300px' }}>
            <Card.Body>
                <Card.Title>
                    Login
                </Card.Title>
                <Form>
                    <Form.Group controlId="formBasicEmail">
                        <Form.Label>Email address</Form.Label>
                        <Form.Control type="email" placeholder="Enter email" />
                        <Form.Text className="text-muted">
                        We'll never share your email with anyone else.
                        </Form.Text>
                    </Form.Group>
                    <Button variant="primary" type="submit" block>
                        Submit
                    </Button>
                </Form>
            </Card.Body>
        </Card>
      </Container>
  )
}
